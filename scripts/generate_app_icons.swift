#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum RenderError: Error, CustomStringConvertible {
    case usage
    case loadFailed(URL)
    case cropFailed
    case rasterFailed
    case contextFailed
    case encodeFailed(URL)

    var description: String {
        switch self {
        case .usage:
            return "Usage: generate_app_icons.swift <source-png> <output-directory>"
        case .loadFailed(let url):
            return "Failed to load source image at \(url.path)"
        case .cropFailed:
            return "Failed to crop source image"
        case .rasterFailed:
            return "Failed to rasterize source image"
        case .contextFailed:
            return "Failed to create drawing context"
        case .encodeFailed(let url):
            return "Failed to encode PNG at \(url.path)"
        }
    }
}

enum IconVariant: CaseIterable {
    case any
    case dark
    case tinted

    var filename: String {
        switch self {
        case .any: return "AppIcon-Any.png"
        case .dark: return "AppIcon-Dark.png"
        case .tinted: return "AppIcon-Tinted.png"
        }
    }
}

struct Palette {
    let background: CGColor
    let strokeAlpha: CGFloat
    let shadowAlpha: CGFloat
    let vignetteAlpha: CGFloat
    let reflectionAlpha: CGFloat
    let causticAlpha: CGFloat
}

let canvasSize = CGSize(width: 1024, height: 1024)
let cropInset: CGFloat = 28
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
    CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
}

func clamp(_ value: CGFloat) -> CGFloat {
    min(max(value, 0), 1)
}

func mix(_ a: CGFloat, _ b: CGFloat, t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

func palette(for variant: IconVariant) -> Palette {
    switch variant {
    case .any:
        return Palette(
            background: color(0.05, 0.08, 0.15),
            strokeAlpha: 0.15,
            shadowAlpha: 0.18,
            vignetteAlpha: 0.20,
            reflectionAlpha: 0.18,
            causticAlpha: 0.07
        )
    case .dark:
        return Palette(
            background: color(0.03, 0.05, 0.11),
            strokeAlpha: 0.13,
            shadowAlpha: 0.24,
            vignetteAlpha: 0.28,
            reflectionAlpha: 0.14,
            causticAlpha: 0.05
        )
    case .tinted:
        return Palette(
            background: color(0.04, 0.06, 0.12),
            strokeAlpha: 0.17,
            shadowAlpha: 0.16,
            vignetteAlpha: 0.18,
            reflectionAlpha: 0.20,
            causticAlpha: 0.08
        )
    }
}

func drawLinearGradient(
    in context: CGContext,
    colors: [CGColor],
    locations: [CGFloat],
    start: CGPoint,
    end: CGPoint
) {
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
        return
    }
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
}

func drawRadialGradient(
    in context: CGContext,
    colors: [CGColor],
    locations: [CGFloat],
    center: CGPoint,
    startRadius: CGFloat,
    endRadius: CGFloat
) {
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
        return
    }
    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: startRadius,
        endCenter: center,
        endRadius: endRadius,
        options: [.drawsAfterEndLocation]
    )
}

func loadCroppedSource(from url: URL) throws -> CGImage {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw RenderError.loadFailed(url)
    }

    let cropRect = CGRect(
        x: cropInset,
        y: cropInset,
        width: CGFloat(image.width) - cropInset * 2,
        height: CGFloat(image.height) - cropInset * 2
    ).integral

    guard let cropped = image.cropping(to: cropRect) else {
        throw RenderError.cropFailed
    }

    return cropped
}

func adjustedColor(
    r: CGFloat,
    g: CGFloat,
    b: CGFloat,
    variant: IconVariant
) -> (CGFloat, CGFloat, CGFloat) {
    func colorControls(
        _ r: CGFloat,
        _ g: CGFloat,
        _ b: CGFloat,
        saturation: CGFloat,
        brightness: CGFloat,
        contrast: CGFloat,
        gamma: CGFloat
    ) -> (CGFloat, CGFloat, CGFloat) {
        let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
        var nr = luma + (r - luma) * saturation
        var ng = luma + (g - luma) * saturation
        var nb = luma + (b - luma) * saturation

        nr = ((nr - 0.5) * contrast + 0.5) + brightness
        ng = ((ng - 0.5) * contrast + 0.5) + brightness
        nb = ((nb - 0.5) * contrast + 0.5) + brightness

        nr = pow(clamp(nr), gamma)
        ng = pow(clamp(ng), gamma)
        nb = pow(clamp(nb), gamma)

        return (nr, ng, nb)
    }

    switch variant {
    case .any:
        return colorControls(r, g, b, saturation: 1.05, brightness: -0.01, contrast: 1.06, gamma: 0.97)
    case .dark:
        return colorControls(r, g, b, saturation: 0.98, brightness: -0.08, contrast: 1.14, gamma: 1.03)
    case .tinted:
        let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let grayscale = pow(clamp(((luma - 0.5) * 1.30) + 0.47), 0.92)
        let dark = (red: CGFloat(0.04), green: CGFloat(0.07), blue: CGFloat(0.12))
        let light = (red: CGFloat(0.92), green: CGFloat(0.98), blue: CGFloat(1.0))
        return (
            mix(dark.red, light.red, t: grayscale),
            mix(dark.green, light.green, t: grayscale),
            mix(dark.blue, light.blue, t: grayscale)
        )
    }
}

func processedImage(from source: CGImage, variant: IconVariant) throws -> CGImage {
    let width = source.width
    let height = source.height
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)

    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        throw RenderError.rasterFailed
    }

    context.interpolationQuality = .high
    context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))

    for index in stride(from: 0, to: pixels.count, by: 4) {
        let alpha = CGFloat(pixels[index + 3]) / 255
        if alpha == 0 { continue }

        let r = CGFloat(pixels[index]) / 255
        let g = CGFloat(pixels[index + 1]) / 255
        let b = CGFloat(pixels[index + 2]) / 255
        let adjusted = adjustedColor(r: r, g: g, b: b, variant: variant)

        pixels[index] = UInt8(clamp(adjusted.0) * 255)
        pixels[index + 1] = UInt8(clamp(adjusted.1) * 255)
        pixels[index + 2] = UInt8(clamp(adjusted.2) * 255)
        pixels[index + 3] = UInt8(alpha * 255)
    }

    guard let provider = CGDataProvider(data: Data(pixels) as CFData) else {
        throw RenderError.rasterFailed
    }

    guard let image = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
    ) else {
        throw RenderError.rasterFailed
    }

    return image
}

func drawFinishingLight(in context: CGContext, variant: IconVariant, rect: CGRect) {
    let tune = palette(for: variant)

    context.saveGState()
    context.setBlendMode(.screen)
    drawRadialGradient(
        in: context,
        colors: [color(0.34, 0.96, 1.0, 0.08), color(0.34, 0.96, 1.0, 0)],
        locations: [0, 1],
        center: CGPoint(x: 760, y: 560),
        startRadius: 0,
        endRadius: 340
    )
    drawRadialGradient(
        in: context,
        colors: [color(0.72, 0.44, 1.0, 0.06), color(0.72, 0.44, 1.0, 0)],
        locations: [0, 1],
        center: CGPoint(x: 250, y: 360),
        startRadius: 0,
        endRadius: 280
    )
    context.restoreGState()

    drawRadialGradient(
        in: context,
        colors: [color(0, 0, 0, 0), color(0, 0, 0, tune.vignetteAlpha)],
        locations: [0.58, 1.0],
        center: CGPoint(x: rect.midX, y: rect.midY),
        startRadius: 280,
        endRadius: 760
    )
}

func drawGlassOverlay(in context: CGContext, variant: IconVariant) {
    let panel = CGRect(x: 10, y: 10, width: 1004, height: 1004)
    let panelPath = CGPath(
        roundedRect: panel,
        cornerWidth: 230,
        cornerHeight: 230,
        transform: nil
    )
    let innerPath = CGPath(
        roundedRect: panel.insetBy(dx: 4, dy: 4),
        cornerWidth: 226,
        cornerHeight: 226,
        transform: nil
    )
    let tune = palette(for: variant)

    context.saveGState()
    context.addPath(panelPath)
    context.clip()

    drawLinearGradient(
        in: context,
        colors: [
            color(1, 1, 1, tune.reflectionAlpha),
            color(1, 1, 1, tune.reflectionAlpha * 0.35),
            color(1, 1, 1, 0)
        ],
        locations: [0, 0.20, 0.68],
        start: CGPoint(x: 512, y: 1040),
        end: CGPoint(x: 512, y: 480)
    )

    context.saveGState()
    context.setBlendMode(.screen)
    drawRadialGradient(
        in: context,
        colors: [color(1, 1, 1, tune.reflectionAlpha * 1.15), color(1, 1, 1, 0)],
        locations: [0, 1],
        center: CGPoint(x: 250, y: 870),
        startRadius: 0,
        endRadius: 420
    )
    drawRadialGradient(
        in: context,
        colors: [color(0.55, 0.95, 1.0, 0.10), color(0.55, 0.95, 1.0, 0)],
        locations: [0, 1],
        center: CGPoint(x: 850, y: 760),
        startRadius: 0,
        endRadius: 360
    )
    drawRadialGradient(
        in: context,
        colors: [color(0.82, 0.55, 1.0, 0.08), color(0.82, 0.55, 1.0, 0)],
        locations: [0, 1],
        center: CGPoint(x: 200, y: 320),
        startRadius: 0,
        endRadius: 280
    )
    context.restoreGState()

    if variant == .tinted {
        context.setBlendMode(.screen)
        context.setFillColor(color(1, 1, 1, 0.035))
        context.fill(panel)
    }

    context.restoreGState()

    context.addPath(panelPath)
    context.setLineWidth(2)
    context.setStrokeColor(color(1, 1, 1, tune.strokeAlpha))
    context.strokePath()

    context.addPath(innerPath)
    context.setLineWidth(1)
    context.setStrokeColor(color(0, 0, 0, tune.shadowAlpha))
    context.strokePath()
}

func renderIcon(source: CGImage, variant: IconVariant, outputURL: URL) throws {
    guard let context = CGContext(
        data: nil,
        width: Int(canvasSize.width),
        height: Int(canvasSize.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        throw RenderError.contextFailed
    }

    let rect = CGRect(origin: .zero, size: canvasSize)
    let tune = palette(for: variant)
    context.setFillColor(tune.background)
    context.fill(rect)

    let filtered = try processedImage(from: source, variant: variant)

    context.saveGState()
    context.interpolationQuality = .high
    context.translateBy(x: 0, y: canvasSize.height)
    context.scaleBy(x: 1, y: -1)
    context.draw(filtered, in: rect.insetBy(dx: -6, dy: -6))
    context.restoreGState()

    drawFinishingLight(in: context, variant: variant, rect: rect)
    drawGlassOverlay(in: context, variant: variant)

    guard
        let image = context.makeImage(),
        let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        )
    else {
        throw RenderError.encodeFailed(outputURL)
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw RenderError.encodeFailed(outputURL)
    }
}

func main() throws {
    let arguments = CommandLine.arguments
    guard arguments.count == 3 else {
        throw RenderError.usage
    }

    let sourceURL = URL(fileURLWithPath: arguments[1])
    let outputDirectory = URL(fileURLWithPath: arguments[2], isDirectory: true)
    let source = try loadCroppedSource(from: sourceURL)

    for variant in IconVariant.allCases {
        try renderIcon(
            source: source,
            variant: variant,
            outputURL: outputDirectory.appendingPathComponent(variant.filename)
        )
    }
}

do {
    try main()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
