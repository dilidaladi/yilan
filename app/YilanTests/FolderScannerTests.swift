import Foundation
import Testing
@testable import Yilan

@Suite("扫描文件夹")
struct FolderScannerTests {
    /// 建一个临时文件夹，放入给定文件名（内容随意）
    private func makeFolder(_ names: [String], subfolders: [String] = []) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("yilan-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for name in names {
            try Data("x".utf8).write(to: dir.appendingPathComponent(name))
        }
        for sub in subfolders {
            let s = dir.appendingPathComponent(sub, isDirectory: true)
            try FileManager.default.createDirectory(at: s, withIntermediateDirectories: true)
            try Data("x".utf8).write(to: s.appendingPathComponent("inside.jpg"))
        }
        return dir
    }

    @Test("只保留支持的扩展名，不区分大小写，跳过隐藏文件和子文件夹")
    func filtersExtensions() throws {
        let dir = try makeFolder(
            ["a.jpg", "b.JPEG", "c.png", "d.webp", "e.HEIC", "f.heif", "g.CR2", "h.cr3", "i.nef", "j.ARW", "k.raf",
             "l.rw2", "m.orf", "n.dng", "o.gif", "p.svg", "q.tif", "r.TIFF", "s.bmp", "t.mp4", "u.m4v", "v.MOV",
             "notes.txt", "doc.pdf", "clip.mkv", "noext", ".hidden.jpg"],
            subfolders: ["sub.jpg", "Nested"]
        )
        defer { try? FileManager.default.removeItem(at: dir) }
        let items = try FolderScanner.scan(folder: dir)
        let names = Set(items.map(\.name))
        #expect(items.count == 22)
        #expect(!names.contains("notes.txt"))
        #expect(!names.contains("clip.mkv"))
        #expect(!names.contains(".hidden.jpg"))
        #expect(!names.contains("sub.jpg"))       // 名字像图片的文件夹也不算
        #expect(!names.contains("inside.jpg"))    // 不进子文件夹
        #expect(items.filter { $0.kind == .video }.count == 3)
        #expect(items.first { $0.name == "j.ARW" }?.format == .raw)
        #expect(items.first { $0.name == "o.gif" }?.format == .gif)
        #expect(items.first { $0.name == "p.svg" }?.format == .svg)
        #expect(items.first { $0.name == "r.TIFF" }?.format == .standard)
    }

    @Test("打开一个文件：扫描所在文件夹并选中它")
    func openFileSelectsIt() throws {
        let dir = try makeFolder(["img1.jpg", "img2.jpg", "img10.jpg", "movie.mov"])
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = try FolderScanner.open(dir.appendingPathComponent("img10.jpg"))
        #expect(result.items.map(\.name) == ["img1.jpg", "img2.jpg", "img10.jpg", "movie.mov"])
        #expect(result.initialIndex == 2)
        #expect(result.folder.standardizedFileURL == dir.standardizedFileURL)
    }

    @Test("打开文件夹：从第一个开始")
    func openFolderStartsAtFirst() throws {
        let dir = try makeFolder(["b.png", "a.png"])
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = try FolderScanner.open(dir)
        #expect(result.initialIndex == 0)
        #expect(result.items.first?.name == "a.png")
    }

    @Test("明确打开不支持的文件，不应改为打开同目录里的图片")
    func unsupportedFileDoesNotSelectAnother() throws {
        let dir = try makeFolder(["img1.jpg", "notes.txt"])
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(throws: FolderScanner.Failure.unsupportedFile) {
            try FolderScanner.open(dir.appendingPathComponent("notes.txt"))
        }
    }

    @Test("空文件夹")
    func emptyFolder() throws {
        let dir = try makeFolder(["readme.md"])
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = try FolderScanner.open(dir)
        #expect(result.items.isEmpty)
        #expect(result.initialIndex == nil)
    }
}

@Suite("自然排序")
struct NaturalSortTests {
    @Test("数字按大小排：img2 在 img10 前面")
    func numbers() {
        let names = ["img10.jpg", "img2.jpg", "img1.jpg", "img20.jpg"]
        #expect(names.sorted(by: FolderScanner.naturalLess) == ["img1.jpg", "img2.jpg", "img10.jpg", "img20.jpg"])
        let camera = ["IMG_0100.jpg", "IMG_020.jpg", "IMG_9.jpg"]
        #expect(camera.sorted(by: FolderScanner.naturalLess) == ["IMG_9.jpg", "IMG_020.jpg", "IMG_0100.jpg"])
    }

    @Test("大小写不敏感")
    func caseInsensitive() {
        let sorted = ["b.jpg", "A.jpg", "a2.jpg", "C.jpg"].sorted(by: FolderScanner.naturalLess)
        #expect(sorted == ["A.jpg", "a2.jpg", "b.jpg", "C.jpg"])
    }

    @Test("排序结果稳定：只有大小写不同的名字也有确定顺序")
    func deterministic() {
        let a = ["photo.JPG", "photo.jpg"].sorted(by: FolderScanner.naturalLess)
        let b = ["photo.jpg", "photo.JPG"].sorted(by: FolderScanner.naturalLess)
        #expect(a == b)
    }
}
