import Charts
import SwiftUI

struct Sparkline: View {
    let points: [Double]
    let isUp: Bool
    var width: CGFloat = 72
    var height: CGFloat = 32

    var body: some View {
        Chart(chartPoints) { point in
            AreaMark(
                x: .value("Index", point.index),
                yStart: .value("Baseline", baseline),
                yEnd: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(areaGradient)

            LineMark(
                x: .value("Index", point.index),
                y: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundStyle(tint)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: yDomain)
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    private var chartPoints: [SparklinePoint] {
        let source = points.isEmpty ? [0.4, 0.7, 0.5, 0.9, 0.65, 1.0] : points
        return source.enumerated().map { SparklinePoint(index: $0.offset, value: $0.element) }
    }

    private var tint: Color {
        isUp ? Color.trendUp : Color.trendDown
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [tint.opacity(0.18), tint.opacity(0.02)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var baseline: Double {
        chartPoints.map(\.value).min() ?? 0
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value)
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1

        guard minValue != maxValue else {
            return (minValue - 1)...(maxValue + 1)
        }

        let padding = (maxValue - minValue) * 0.18
        return (minValue - padding)...(maxValue + padding)
    }
}

private struct SparklinePoint: Identifiable {
    let index: Int
    let value: Double

    var id: Int { index }
}

#Preview("Sparkline") {
    VStack(alignment: .leading, spacing: 20) {
        Sparkline(points: [0.4, 0.55, 0.5, 0.8, 0.74, 1.1, 0.95], isUp: true)
        Sparkline(points: [1.1, 0.9, 1.0, 0.7, 0.62, 0.5, 0.46], isUp: false)
    }
    .padding(24)
    .background(Color.canvas)
}
