import AppKit
let output = CommandLine.arguments[1]
let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let background = NSBezierPath(roundedRect: NSRect(x: 35, y: 35, width: 954, height: 954), xRadius: 220, yRadius: 220)
NSGradient(starting: NSColor(red: 0.91, green: 0.94, blue: 0.84, alpha: 1), ending: NSColor(red: 0.60, green: 0.73, blue: 0.58, alpha: 1))!.draw(in: background, angle: -90)
NSColor(red: 1, green: 0.96, blue: 0.78, alpha: 0.8).setFill()
NSBezierPath(ovalIn: NSRect(x: 690, y: 685, width: 110, height: 110)).fill()
let book = NSBezierPath()
book.move(to: NSPoint(x: 210, y: 305)); book.line(to: NSPoint(x: 210, y: 575)); book.curve(to: NSPoint(x: 512, y: 515), controlPoint1: NSPoint(x: 335, y: 610), controlPoint2: NSPoint(x: 460, y: 550)); book.curve(to: NSPoint(x: 814, y: 575), controlPoint1: NSPoint(x: 575, y: 550), controlPoint2: NSPoint(x: 700, y: 610)); book.line(to: NSPoint(x: 814, y: 305)); book.curve(to: NSPoint(x: 512, y: 270), controlPoint1: NSPoint(x: 700, y: 345), controlPoint2: NSPoint(x: 585, y: 320)); book.curve(to: NSPoint(x: 210, y: 305), controlPoint1: NSPoint(x: 430, y: 320), controlPoint2: NSPoint(x: 315, y: 345)); book.close()
NSColor(red: 0.99, green: 0.97, blue: 0.88, alpha: 1).setFill(); book.fill()
let stem = NSBezierPath(); stem.move(to: NSPoint(x: 512, y: 305)); stem.curve(to: NSPoint(x: 535, y: 715), controlPoint1: NSPoint(x: 485, y: 455), controlPoint2: NSPoint(x: 500, y: 630)); stem.lineWidth = 17; stem.lineCapStyle = .round; NSColor(red: 0.26, green: 0.40, blue: 0.30, alpha: 1).setStroke(); stem.stroke()
let leaf = NSBezierPath(); leaf.move(to: NSPoint(x: 516, y: 604)); leaf.curve(to: NSPoint(x: 685, y: 779), controlPoint1: NSPoint(x: 500, y: 722), controlPoint2: NSPoint(x: 605, y: 776)); leaf.curve(to: NSPoint(x: 516, y: 604), controlPoint1: NSPoint(x: 690, y: 660), controlPoint2: NSPoint(x: 610, y: 599)); NSColor(red: 0.28, green: 0.45, blue: 0.32, alpha: 1).setFill(); leaf.fill()
let left = NSBezierPath(); left.move(to: NSPoint(x: 508, y: 560)); left.curve(to: NSPoint(x: 365, y: 716), controlPoint1: NSPoint(x: 403, y: 557), controlPoint2: NSPoint(x: 360, y: 620)); left.curve(to: NSPoint(x: 508, y: 560), controlPoint1: NSPoint(x: 480, y: 716), controlPoint2: NSPoint(x: 519, y: 646)); left.fill()
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
