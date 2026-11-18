import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Yilan

@Suite("轻编辑与副本保存")
struct PhotoEditTests {
    private func withSource() throws -> (URL, URL) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("yilan-edit-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let source = folder.appendingPathComponent("source.png")
        let ctx = try #require(CGContext(data: nil, width: 80, height: 60, bitsPerComponent: 8, bytesPerRow: 0,
                                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.setFillColor(red: 0.8, green: 0.05, blue: 0.2, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 60))
        let writer = try #require(CGImageDestinationCreateWithURL(source as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(writer, try #require(ctx.makeImage()), nil)
        try #require(CGImageDestinationFinalize(writer))
        return (folder, source)
    }

    @Test("裁切、旋转、缩小后导出；重复保存不覆盖源文件和旧副本")
    func exportsUniqueCopies() throws {
        let (folder, source) = try withSource()
        defer { try? FileManager.default.removeItem(at: folder) }
        let original = try Data(contentsOf: source)
        var edit = PhotoEdit(crop: CGRect(x: 0, y: 0, width: 0.5, height: 1), percent: 50)
        edit.rotateRight()
        let first = try edit.export(source, format: .png)
        let firstBytes = try Data(contentsOf: first)
        let second = try edit.export(source, format: .png)
        #expect(first != source && first != second)
        #expect(try Data(contentsOf: source) == original)
        #expect(try Data(contentsOf: first) == firstBytes)
        #expect(try PhotoEdit.preview(first).size == CGSize(width: 30, height: 20))
        #expect(second.deletingPathExtension().lastPathComponent.hasSuffix(" 2"))
        // 左半幅有色、右半幅透明。右转后裁出的上半幅应当全是不透明像素。
        let cropped = try PhotoEdit.preview(first).image
        let ctx = try #require(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
                                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let rgba = try #require(ctx.data).assumingMemoryBound(to: UInt8.self)
        #expect(rgba[0] > 140 && rgba[3] == 255)
    }

    @Test("越界输出被拒绝，不创建副本")
    func rejectsUnsupportedSize() throws {
        let (folder, source) = try withSource()
        defer { try? FileManager.default.removeItem(at: folder) }
        let edit = PhotoEdit(percent: 201)
        #expect(throws: PhotoEdit.Failure.self) { try edit.export(source, format: .jpg) }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == ["source.png"])
    }

    @Test("JPEG 副本可读，旋转后宽高交换")
    func jpegCopy() throws {
        let (folder, source) = try withSource()
        defer { try? FileManager.default.removeItem(at: folder) }
        let copy = try PhotoEdit(turns: 1).export(source, format: .jpg)
        let opened = try #require(CGImageSourceCreateWithURL(copy as CFURL, nil))
        #expect(CGImageSourceGetType(opened) as String? == UTType.jpeg.identifier)
        #expect(try PhotoEdit.preview(copy).size == CGSize(width: 60, height: 80))
    }

    @Test("EXIF 方向在预览与副本中一致")
    func keepsDisplayedOrientation() throws {
        let (folder, source) = try withSource()
        defer { try? FileManager.default.removeItem(at: folder) }
        let rotated = folder.appendingPathComponent("camera.jpg")
        let image = try PhotoEdit.preview(source).image
        let writer = try #require(CGImageDestinationCreateWithURL(rotated as CFURL, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(writer, image, [kCGImagePropertyOrientation: 6] as CFDictionary)
        try #require(CGImageDestinationFinalize(writer))
        #expect(try PhotoEdit.preview(rotated).size == CGSize(width: 60, height: 80))
        let copy = try PhotoEdit().export(rotated, format: .png)
        #expect(try PhotoEdit.preview(copy).size == CGSize(width: 60, height: 80))
    }
}
