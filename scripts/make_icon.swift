// Renders the app icon into an .iconset folder: swiftc make_icon.swift && ./make_icon <out.iconset>
import AppKit

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: size / 1024, y: size / 1024)

    // macOS icon grid: 824pt rounded square centered on a 1024 canvas, with a soft drop shadow.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    ctx.addPath(tilePath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    let background = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(red: 0.20, green: 0.55, blue: 0.98, alpha: 1).cgColor,
        NSColor(red: 0.07, green: 0.20, blue: 0.55, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(background, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    ctx.restoreGState()

    // Globe: white disc with latitude / longitude lines.
    let center = CGPoint(x: 512, y: 512)
    let radius: CGFloat = 300
    let globe = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    ctx.setFillColor(NSColor(white: 1, alpha: 0.96).cgColor)
    ctx.fillEllipse(in: globe)

    ctx.saveGState()
    ctx.addEllipse(in: globe)
    ctx.clip()
    ctx.setStrokeColor(NSColor(red: 0.20, green: 0.50, blue: 0.95, alpha: 0.28).cgColor)
    ctx.setLineWidth(10)
    for fraction in [0.35, 0.72] as [CGFloat] {   // meridians
        let w = radius * fraction
        ctx.strokeEllipse(in: CGRect(x: center.x - w, y: center.y - radius, width: w * 2, height: radius * 2))
    }
    ctx.move(to: CGPoint(x: center.x, y: center.y - radius))
    ctx.addLine(to: CGPoint(x: center.x, y: center.y + radius))
    for offset in [-150, 0, 150] as [CGFloat] {   // parallels
        let y = center.y + offset
        ctx.move(to: CGPoint(x: center.x - radius, y: y))
        ctx.addLine(to: CGPoint(x: center.x + radius, y: y))
    }
    ctx.strokePath()
    ctx.restoreGState()

    // Hour ticks.
    ctx.setStrokeColor(NSColor(red: 0.07, green: 0.20, blue: 0.55, alpha: 1).cgColor)
    ctx.setLineCap(.round)
    for hour in 0..<12 {
        let angle = CGFloat(hour) * .pi / 6
        let outer = radius - 30, inner = radius - (hour % 3 == 0 ? 80 : 58)
        ctx.setLineWidth(hour % 3 == 0 ? 18 : 10)
        ctx.move(to: CGPoint(x: center.x + sin(angle) * inner, y: center.y + cos(angle) * inner))
        ctx.addLine(to: CGPoint(x: center.x + sin(angle) * outer, y: center.y + cos(angle) * outer))
        ctx.strokePath()
    }

    // Hands at 10:10.
    func hand(angle: CGFloat, length: CGFloat, width: CGFloat, color: NSColor) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.move(to: center)
        ctx.addLine(to: CGPoint(x: center.x + sin(angle) * length, y: center.y + cos(angle) * length))
        ctx.strokePath()
    }
    let navy = NSColor(red: 0.07, green: 0.16, blue: 0.40, alpha: 1)
    hand(angle: (10 + 10.0 / 60) / 12 * 2 * .pi, length: 150, width: 30, color: navy)
    hand(angle: 10.0 / 60 * 2 * .pi, length: 225, width: 22, color: navy)
    hand(angle: 40.0 / 60 * 2 * .pi, length: 235, width: 8, color: NSColor(red: 1, green: 0.55, blue: 0.10, alpha: 1))
    ctx.setFillColor(navy.cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52))
    ctx.setFillColor(NSColor(red: 1, green: 0.55, blue: 0.10, alpha: 1).cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let png = drawIcon(size: CGFloat(base * scale)).representation(using: .png, properties: [:])!
        try png.write(to: outDir.appendingPathComponent(name))
    }
}
