import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PhotoEdit: Sendable {
    static let full = CGRect(x: 0, y: 0, width: 1, height: 1)
    static let maxPixels = 48_000_000
    static let maxSide = 16_384

    var turns = 0
    var crop = Self.full
    var percent = 100

    enum Format: String, CaseIterable, Identifiable, Sendable {
        case png, jpg
        var id: Self { self }
        var type: UTType { self == .png ? .png : .jpeg }
        var label: String { self == .png ? "PNG" : "JPEG" }
    }

    enum Failure: LocalizedError {
        case unreadable, tooLarge, cannotExport, sourceChanged

        var errorDescription: String? {
            switch self {
            case .unreadable: String(localized: "无法编辑这张图片。")
            case .tooLarge: String(localized: "轻编辑最多支持 4800 万像素，且单边不超过 16384 像素。")
            case .cannotExport: String(localized: "无法保存图片副本。")
            case .sourceChanged: String(localized: "原图已变化，请关闭轻编辑并重新打开。")
            }
        }
    }

    struct Preview: Sendable {
        let image: CGImage
        let size: CGSize
    }

    private static func checkSize(_ width: Int, _ height: Int) throws {
        guard width > 0, height > 0, width <= maxSide, height <= maxSide, width * height <= maxPixels else {
            throw Failure.tooLarge
        }
    }

    private static func load(_ url: URL, preview: Bool) throws -> Preview {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) == 1,
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int else { throw Failure.unreadable }
        try checkSize(width, height)
        let orientation = props[kCGImagePropertyOrientation] as? Int ?? 1
        let size = (5...8).contains(orientation) ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: preview ? min(1200, max(width, height)) : max(width, height),
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { throw Failure.unreadable }
        return Preview(image: image, size: size)
    }

    static func preview(_ url: URL) throws -> Preview { try load(url, preview: true) }

    var normalizedTurns: Int { (turns % 4 + 4) % 4 }

    mutating func rotateRight() {
        turns = (normalizedTurns + 1) % 4
        crop = CGRect(x: 1 - crop.maxY, y: crop.minX, width: crop.height, height: crop.width)
    }

    func rotatedSize(_ size: CGSize) -> CGSize {
        normalizedTurns.isMultiple(of: 2) ? size : CGSize(width: size.height, height: size.width)
    }

    func cropPixels(_ size: CGSize) -> CGRect {
        CGRect(x: crop.minX * size.width, y: crop.minY * size.height,
               width: crop.width * size.width, height: crop.height * size.height)
            .integral.intersection(CGRect(origin: .zero, size: size))
    }

    func outputSize(_ source: CGSize) -> CGSize {
        let rect = cropPixels(rotatedSize(source))
        guard !rect.isEmpty, !rect.isNull, (1...200).contains(percent) else { return .zero }
        let scale = CGFloat(percent) / 100
        return CGSize(width: max(1, (rect.width * scale).rounded()), height: max(1, (rect.height * scale).rounded()))
    }

    func allowsOutput(_ source: CGSize) -> Bool {
        let size = outputSize(source)
        return (try? Self.checkSize(Int(size.width), Int(size.height))) != nil
    }

    private static func rotate(_ image: CGImage, turns: Int) throws -> CGImage {
        guard turns != 0 else { return image }
        let swapped = !turns.isMultiple(of: 2)
        let width = swapped ? image.height : image.width
        let height = swapped ? image.width : image.height
        let ctx = try context(width, height)
        ctx.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
        ctx.rotate(by: -CGFloat(turns) * .pi / 2)
        ctx.draw(image, in: CGRect(x: -CGFloat(image.width) / 2, y: -CGFloat(image.height) / 2,
                                  width: CGFloat(image.width), height: CGFloat(image.height)))
        guard let result = ctx.makeImage() else { throw Failure.cannotExport }
        return result
    }

    private static func context(_ width: Int, _ height: Int, opaque: Bool = false) throws -> CGContext {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue)
        else { throw Failure.cannotExport }
        return ctx
    }

    func export(_ url: URL, format: Format) throws -> URL {
        let source = try Self.load(url, preview: false)
        let output = outputSize(source.size)
        let width = Int(output.width), height = Int(output.height)
        try Self.checkSize(width, height)
        let rotated = try Self.rotate(source.image, turns: normalizedTurns)
        let rect = cropPixels(CGSize(width: rotated.width, height: rotated.height))
        guard !rect.isEmpty, let cropped = rotated.cropping(to: rect) else { throw Failure.cannotExport }

        let image: CGImage
        if format == .png, cropped.width == width, cropped.height == height {
            image = cropped
        } else {
            let ctx = try Self.context(width, height, opaque: format == .jpg)
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            if format == .jpg {
                ctx.setFillColor(CGColor(gray: 1, alpha: 1))
                ctx.fill(bounds)
            }
            ctx.interpolationQuality = .high
            ctx.draw(cropped, in: bounds)
            guard let rendered = ctx.makeImage() else { throw Failure.cannotExport }
            image = rendered
        }

        let folder = url.deletingLastPathComponent()
        let temporary = folder.appendingPathComponent(".yilan-copy-\(UUID().uuidString)")
        let fm = FileManager.default
        defer { try? fm.removeItem(at: temporary) }
        guard let destination = CGImageDestinationCreateWithURL(temporary as CFURL, format.type.identifier as CFString, 1, nil)
        else { throw Failure.cannotExport }
        let options: CFDictionary? = format == .jpg ? [kCGImageDestinationLossyCompressionQuality: 0.94] as CFDictionary : nil
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else { throw Failure.cannotExport }

        let base = url.deletingPathExtension().lastPathComponent
        let edited = String(localized: "\(base) 编辑")
        for suffix in 1...1000 {
            let name = suffix == 1 ? edited : "\(edited) \(suffix)"
            let target = folder.appendingPathComponent(name).appendingPathExtension(format.rawValue)
            do {
                try fm.moveItem(at: temporary, to: target)
                return target
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                continue
            }
        }
        throw Failure.cannotExport
    }
}
