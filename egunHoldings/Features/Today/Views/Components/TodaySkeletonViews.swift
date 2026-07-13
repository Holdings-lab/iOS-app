import SwiftUI

// Loading placeholders for the 4 Today tab sections. Each shape hints at its real content
// (short lines for the briefing, repeating rows for holdings, etc.) so users can tell
// what's loading, following the SignalSkeletonStack (.redacted(reason: .placeholder)) pattern
// in Features/Signal/Views/SignalView.swift.

struct TodayBriefingSkeleton: View {
    var body: some View {
        KDXCard {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 60, height: 16)
                    RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 80, height: 32)
                }
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(height: 14)
                    RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(height: 14)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct TodayHoldingsSkeleton: View {
    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 110, height: 16)
                VStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 120, height: 14)
                                Spacer()
                                RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 40, height: 14)
                            }
                            RoundedRectangle(cornerRadius: 4).fill(Color.divider).frame(height: 6)
                        }
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct TodayGoalProgressSkeleton: View {
    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 14) {
                RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 90, height: 16)
                RoundedRectangle(cornerRadius: 5).fill(Color.divider).frame(height: 8)
                RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 220, height: 14)
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct TodayNewsSkeleton: View {
    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 140, height: 16)
                VStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(height: 14)
                            RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 220, height: 12)
                        }
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}
