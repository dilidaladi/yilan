import Foundation
import Testing
@testable import Yilan

private func item(_ name: String) -> MediaItem {
    let url = URL(fileURLWithPath: "/tmp/fixture/\(name)")
    return MediaItem(url: url, format: SupportedFormats.format(forExtension: url.pathExtension)!,
                     fileSize: 100, modificationDate: Date(timeIntervalSince1970: 1_000))
}

@Suite("类型切换：停在原位或跳到最近的一个")
struct FilterSelectionTests {
    // 图 图 视 图 视 视 图
    let all = ["a.jpg", "b.jpg", "c.mov", "d.jpg", "e.mp4", "f.mov", "g.jpg"].map(item)

    @Test("每种类型的列表")
    func lists() {
        #expect(MediaFilter.all.apply(all).count == 7)
        #expect(MediaFilter.images.apply(all).map(\.name) == ["a.jpg", "b.jpg", "d.jpg", "g.jpg"])
        #expect(MediaFilter.videos.apply(all).map(\.name) == ["c.mov", "e.mp4", "f.mov"])
    }

    @Test("当前文件还在新列表里：停在原位")
    func keepsCurrent() {
        let images = MediaFilter.images.apply(all)
        let i = FilterSelection.index(keeping: all[3], in: all, newList: images)   // d.jpg
        #expect(images[i!].name == "d.jpg")
        // 从“只看图片”切回“全部”
        let back = FilterSelection.index(keeping: images[i!], in: all, newList: all)
        #expect(back == 3)
    }

    @Test("当前文件不在新列表里：跳到离它最近的一个")
    func jumpsToNearest() {
        let images = MediaFilter.images.apply(all)
        let videos = MediaFilter.videos.apply(all)
        // c.mov(2) → 最近的图片：b.jpg(1) 和 d.jpg(3) 一样近，取后面的 d.jpg
        #expect(images[FilterSelection.index(keeping: all[2], in: all, newList: images)!].name == "d.jpg")
        // f.mov(5) → g.jpg(6) 最近
        #expect(images[FilterSelection.index(keeping: all[5], in: all, newList: images)!].name == "g.jpg")
        // a.jpg(0) → 最近的视频 c.mov(2)
        #expect(videos[FilterSelection.index(keeping: all[0], in: all, newList: videos)!].name == "c.mov")
        // g.jpg(6) → 最近的视频 f.mov(5)
        #expect(videos[FilterSelection.index(keeping: all[6], in: all, newList: videos)!].name == "f.mov")
        // d.jpg(3) → c.mov(2) 和 e.mp4(4) 一样近，取后面的 e.mp4
        #expect(videos[FilterSelection.index(keeping: all[3], in: all, newList: videos)!].name == "e.mp4")
    }

    @Test("新列表为空返回 nil；没有当前项时从第一个开始")
    func edgeCases() {
        let onlyImages = ["a.jpg", "b.png"].map(item)
        #expect(FilterSelection.index(keeping: onlyImages[0], in: onlyImages, newList: []) == nil)
        #expect(FilterSelection.index(keeping: nil, in: onlyImages, newList: onlyImages) == 0)
    }
}

@Suite("缩略图缓存键")
struct ThumbnailCacheKeyTests {
    let date = Date(timeIntervalSince1970: 1_762_400_000.123)

    @Test("同一文件同一状态：键相同，且是 64 位十六进制")
    func stable() {
        let a = ThumbnailCacheKey.make(path: "/a/b.jpg", modificationDate: date, fileSize: 42)
        let b = ThumbnailCacheKey.make(path: "/a/b.jpg", modificationDate: date, fileSize: 42)
        #expect(a == b)
        #expect(a.count == 64)
        #expect(a.allSatisfy { $0.isHexDigit })
    }

    @Test("路径、修改时间、大小任何一个变了，键就变")
    func changes() {
        let base = ThumbnailCacheKey.make(path: "/a/b.jpg", modificationDate: date, fileSize: 42)
        #expect(base != ThumbnailCacheKey.make(path: "/a/c.jpg", modificationDate: date, fileSize: 42))
        #expect(base != ThumbnailCacheKey.make(path: "/a/b.jpg", modificationDate: date.addingTimeInterval(1), fileSize: 42))
        #expect(base != ThumbnailCacheKey.make(path: "/a/b.jpg", modificationDate: date, fileSize: 43))
    }

    @Test("修改时间按毫秒取整，微小的浮点误差不影响")
    func millisecondRounding() {
        let a = ThumbnailCacheKey.make(path: "/x.jpg", modificationDate: date, fileSize: 1)
        let b = ThumbnailCacheKey.make(path: "/x.jpg", modificationDate: date.addingTimeInterval(0.0000001), fileSize: 1)
        #expect(a == b)
    }

    @Test("MediaItem 的键用标准化路径")
    func itemKey() {
        let i = item("photo.jpg")
        #expect(ThumbnailCacheKey.make(for: i) ==
                ThumbnailCacheKey.make(path: "/tmp/fixture/photo.jpg", modificationDate: i.modificationDate, fileSize: 100))
    }
}
