import AppKit

// Renders the music apps' own icons (Apple Music, Spotify) to small PNGs so the
// square layout can badge whichever app is playing. Pulled from the user's
// installed apps at run time (like the album art) and NOT shipped. Apps that
// aren't installed are skipped. Requires Xcode Command Line Tools (`swift`).

let outDir = CommandLine.arguments[1]
let side = 128   // px; shown small, oversized for retina crispness

// (bundle id, output filename)
let apps = [
  ("com.apple.Music", "app-music.png"),
  ("com.spotify.client", "app-spotify.png"),
]

let ws = NSWorkspace.shared

for (bundleId, outName) in apps {
  guard let url = ws.urlForApplication(withBundleIdentifier: bundleId) else {
    print("SKIP \(bundleId) (not installed)"); continue
  }
  let icon = ws.icon(forFile: url.path)

  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  NSGraphicsContext.current?.imageInterpolation = .high
  icon.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
  NSGraphicsContext.restoreGraphicsState()

  try! rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: outDir + "/" + outName))
  print("OK \(outName)")
}
