import Cocoa

// Standalone command-line tool: renders the Awake app icon at every size
// required by `iconutil` and writes PNGs into the given output directory.
// Usage: IconGen <output-directory>

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("Usage: IconGen <output-directory>\n".data(using: .utf8)!)
    exit(1)
}

let outputDir = CommandLine.arguments[1]
let fileManager = FileManager.default
try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let targets: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for target in targets {
    let image = IconFactory.makeAppIcon(size: target.size)
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        continue
    }
    let path = (outputDir as NSString).appendingPathComponent("\(target.name).png")
    try? png.write(to: URL(fileURLWithPath: path))
    print("Wrote \(path)")
}
