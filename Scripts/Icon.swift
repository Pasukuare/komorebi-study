import AppKit

// Reproducible rasterization of the approved vector master; no installed fonts.
// Usage: swift Icon.swift output.png [master.svg] [pixelSize]
let args = CommandLine.arguments
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let source = args.count > 2 ? URL(fileURLWithPath: args[2]) : root.appendingPathComponent("DesignProposals/Identity-D-Final/icona-D-chiara-1024.svg")
let pixels = args.count > 3 ? Int(args[3])! : 1024
let image = NSImage(contentsOf: source)!
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[1]))
