import AppKit

let symbols: [(String, String)] = [
    ("sun", "sun.max.fill"),
    ("news", "newspaper.fill"),
    ("pie", "chart.pie.fill"),
    ("bell", "bell"),
    ("gear", "gearshape"),
    ("chevron", "chevron.right"),
    ("back", "chevron.left"),
    ("plus", "plus"),
    ("close", "xmark"),
    ("photo", "photo"),
    ("alert", "exclamationmark.triangle.fill"),
    ("refresh", "arrow.clockwise"),
    ("external", "arrow.up.forward.square")
]

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for (name, systemName) in symbols {
    guard let original = NSImage(systemSymbolName: systemName, accessibilityDescription: nil),
          let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 96, pixelsHigh: 96,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
          ),
          let context = NSGraphicsContext(bitmapImageRep: bitmap)
    else { fatalError("Cannot render SF Symbol: \(systemName)") }

    let image = original.withSymbolConfiguration(.init(pointSize: 72, weight: .regular)) ?? original
    let bounds = NSRect(x: 0, y: 0, width: 96, height: 96)
    let source = image.size
    let scale = min(80 / source.width, 80 / source.height)
    let size = NSSize(width: source.width * scale, height: source.height * scale)
    let destination = NSRect(
        x: (bounds.width - size.width) / 2,
        y: (bounds.height - size.height) / 2,
        width: size.width,
        height: size.height
    )

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    NSColor.clear.setFill()
    bounds.fill()
    image.draw(in: destination, from: .zero, operation: .sourceOver, fraction: 1)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Cannot encode SF Symbol: \(systemName)")
    }
    try data.write(to: output.appendingPathComponent("\(name).png"))
}
