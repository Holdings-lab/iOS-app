#!/usr/bin/env bash

# Checks the project metadata that can be verified before an Apple Developer
# Program membership or an App Store Connect account is available.

set -euo pipefail

readonly REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_PATH="$REPOSITORY_ROOT/egunHoldings.xcodeproj"
readonly INFO_PLIST_PATH="$REPOSITORY_ROOT/Config/Info.plist"
readonly APP_ICON_PATH="$REPOSITORY_ROOT/egunHoldings/DesignSystem/Assets.xcassets/AppIcon.appiconset"

scheme="egunHoldings"
static_only=false
failures=0

usage() {
    cat <<'EOF'
Usage: bash scripts/testflight_preflight.sh [--scheme <name>] [--static-only]

Checks release metadata, the app icon, and (unless --static-only is used) the
resolved Release build settings. It never signs, archives, uploads, or reads
Apple account credentials.
EOF
}

pass() {
    printf 'PASS  %s\n' "$1"
}

warn() {
    printf 'WARN  %s\n' "$1"
}

fail() {
    printf 'FAIL  %s\n' "$1"
    failures=$((failures + 1))
}

require_file() {
    local path="$1"
    local label="$2"

    if [[ -f "$path" ]]; then
        pass "$label"
    else
        fail "$label is missing: $path"
    fi
}

plist_value() {
    local key="$1"
    plutil -extract "$key" raw -o - "$INFO_PLIST_PATH" 2>/dev/null || true
}

build_setting() {
    local key="$1"
    awk -F ' = ' -v key="$key" '$1 ~ ("[[:space:]]" key "$") { print $2; exit }'
}

while (($#)); do
    case "$1" in
        --scheme)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            scheme="$2"
            shift 2
            ;;
        --static-only)
            static_only=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

printf 'TestFlight preflight: %s\n' "$scheme"
require_file "$PROJECT_PATH/project.pbxproj" "Xcode project"
require_file "$INFO_PLIST_PATH" "App Info.plist"
require_file "$APP_ICON_PATH/Contents.json" "App icon manifest"
require_file "$APP_ICON_PATH/AppIcon-Any.png" "1024px default app icon"

if [[ -f "$INFO_PLIST_PATH" ]]; then
    if [[ "$(plist_value CFBundleShortVersionString)" == '$(MARKETING_VERSION)' ]]; then
        pass 'Info.plist uses MARKETING_VERSION'
    else
        fail 'CFBundleShortVersionString must use $(MARKETING_VERSION)'
    fi

    if [[ "$(plist_value CFBundleVersion)" == '$(CURRENT_PROJECT_VERSION)' ]]; then
        pass 'Info.plist uses CURRENT_PROJECT_VERSION'
    else
        fail 'CFBundleVersion must use $(CURRENT_PROJECT_VERSION)'
    fi
fi

if [[ -f "$APP_ICON_PATH/AppIcon-Any.png" ]] && command -v sips >/dev/null; then
    icon_dimensions="$(sips -g pixelWidth -g pixelHeight "$APP_ICON_PATH/AppIcon-Any.png")"
    icon_width="$(awk '/pixelWidth:/ { print $2 }' <<<"$icon_dimensions")"
    icon_height="$(awk '/pixelHeight:/ { print $2 }' <<<"$icon_dimensions")"

    if [[ "$icon_width" == 1024 && "$icon_height" == 1024 ]]; then
        pass 'Default app icon is 1024 by 1024 pixels'
    else
        fail "Default app icon must be 1024 by 1024 pixels (found ${icon_width:-unknown} by ${icon_height:-unknown})"
    fi
fi

if [[ "$static_only" == true ]]; then
    warn 'Skipped resolved Release build settings (--static-only).'
    warn 'Run again without --static-only in a normal local Xcode environment before archiving.'
elif ! command -v xcodebuild >/dev/null; then
    fail 'xcodebuild is unavailable. Install/select full Xcode, then run this script again.'
else
    if ! settings="$(xcodebuild -showBuildSettings -project "$PROJECT_PATH" -scheme "$scheme" -configuration Release 2>&1)"; then
        fail 'Could not load Release build settings. Resolve the Xcode error, then rerun this script.'
        printf '%s\n' "$settings"
    else
        bundle_id="$(build_setting PRODUCT_BUNDLE_IDENTIFIER <<<"$settings")"
        marketing_version="$(build_setting MARKETING_VERSION <<<"$settings")"
        build_number="$(build_setting CURRENT_PROJECT_VERSION <<<"$settings")"
        team_id="$(build_setting DEVELOPMENT_TEAM <<<"$settings")"
        signing_style="$(build_setting CODE_SIGN_STYLE <<<"$settings")"

        if [[ "$bundle_id" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
            pass "Bundle identifier: $bundle_id"
        else
            fail "Bundle identifier is missing or malformed: ${bundle_id:-<empty>}"
        fi

        if [[ "$marketing_version" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
            pass "Marketing version: $marketing_version"
        else
            fail "Marketing version must use numeric dot notation: ${marketing_version:-<empty>}"
        fi

        if [[ "$build_number" =~ ^[1-9][0-9]*$ ]]; then
            pass "Build number: $build_number"
        else
            fail "Build number must be a positive integer: ${build_number:-<empty>}"
        fi

        if [[ "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
            warn "Configured Team ID: $team_id. Confirm it is the enrolled account's team before archiving."
        else
            fail "Development team must be a 10-character Apple Team ID: ${team_id:-<empty>}"
        fi

        if [[ "$signing_style" == Automatic ]]; then
            pass 'Automatic code signing is enabled'
        else
            fail "Expected automatic code signing, found: ${signing_style:-<empty>}"
        fi

        if [[ -z "$(build_setting CODE_SIGN_ENTITLEMENTS <<<"$settings")" ]]; then
            warn 'No app entitlements are configured. Add Push Notifications only when the backend can register and send device tokens.'
        fi
    fi
fi

if ((failures > 0)); then
    printf '\nPreflight failed with %d issue(s).\n' "$failures"
    exit 1
fi

printf '\nPreflight completed without blocking issues.\n'
