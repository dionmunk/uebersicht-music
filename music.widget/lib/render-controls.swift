import AppKit

// Renders the transport-control SF Symbols to white silhouette PNGs (<name>.ink.png)
// used as CSS masks, so the buttons take the theme colour. Generated locally on first
// run and NOT shipped (SF Symbols aren't ours to redistribute). Requires Xcode
// Command Line Tools (`swift`).

let names = ["backward.fill", "play.fill", "pause.fill", "forward.fill", "shuffle", "repeat", "repeat.1"]
let outDir = CommandLine.arguments[1]
let cfg = NSImage.SymbolConfiguration(pointSize: 200, weight: .regular)

func newBitmap(_ w: Int, _ h: Int) -> NSBitmapImageRep {
  NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
}

for name in names {
  guard let sym = NSImage(systemSymbolName: name, accessibilityDescription: nil),
        let img = sym.withSymbolConfiguration(cfg) else { print("MISS \(name)"); continue }
  img.isTemplate = false
  let sz = img.size
  let w = Int(sz.width.rounded()), h = Int(sz.height.rounded())

  let src = newBitmap(w, h)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: src)
  img.draw(in: NSRect(origin: .zero, size: sz))
  NSGraphicsContext.restoreGraphicsState()

  let ink = newBitmap(w, h)
  let clear = NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 0)
  for y in 0..<h {
    for x in 0..<w {
      guard let c = src.colorAt(x: x, y: y) else { continue }
      let a = c.alphaComponent
      ink.setColor(a < 0.05 ? clear : NSColor(deviceRed: 1, green: 1, blue: 1, alpha: a), atX: x, y: y)
    }
  }

  try! ink.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: outDir + "/" + name + ".ink.png"))
  print("OK \(name)  \(w)x\(h)")
}
