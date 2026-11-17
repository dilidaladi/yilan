import Foundation

/// 拖入窗口时遮罩上的说明（设计稿 04 · 拖入文件夹）
struct DropSummary: Equatable, Sendable {
    /// 例如：松开以打开“2026 冬 · 北海道”
    let title: String
    /// 例如：共 128 个文件：112 张图片，16 个视频
    let detail: String
    /// 能不能打开（不支持的文件显示禁止标记）
    let acceptable: Bool

    /// 还没读到拖动内容时的通用文案
    static var pending: DropSummary {
        DropSummary(title: String(localized: "松开以打开"), detail: String(localized: "图片、视频或文件夹"), acceptable: true)
    }

    /// 数量说明，例如“共 128 个文件：112 张图片，16 个视频”。
    /// 每种组合都是一整句（英文要按数量变单复数，不能拼接）
    /// - Parameter locale: 只在测试里指定，默认用当前界面语言
    static func countText(images: Int, videos: Int, inParentFolder: Bool = false, locale: Locale? = nil) -> String {
        let total = images + videos
        var text: LocalizedStringResource
        switch (images > 0, videos > 0, inParentFolder) {
        case (false, false, false): text = "这个文件夹里没有图片或视频"
        case (false, false, true): text = "所在文件夹里没有其他图片或视频"
        case (true, true, false): text = "共 \(total) 个文件：\(images) 张图片，\(videos) 个视频"
        case (true, false, false): text = "共 \(total) 个文件：\(images) 张图片"
        case (false, true, false): text = "共 \(total) 个文件：\(videos) 个视频"
        case (true, true, true): text = "所在文件夹共 \(total) 个文件：\(images) 张图片，\(videos) 个视频"
        case (true, false, true): text = "所在文件夹共 \(total) 个文件：\(images) 张图片"
        case (false, true, true): text = "所在文件夹共 \(total) 个文件：\(videos) 个视频"
        }
        if let locale { text.locale = locale }
        return String(localized: text)
    }

    /// 读取拖进来的文件或文件夹（会扫描文件夹，在后台线程调用）
    static func describe(_ url: URL) -> DropSummary {
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        if isDirectory {
            let items = (try? FolderScanner.scan(folder: url)) ?? []
            return DropSummary(title: String(localized: "松开以打开“\(url.lastPathComponent)”"), detail: counts(items), acceptable: true)
        }
        guard SupportedFormats.format(forExtension: url.pathExtension) != nil else {
            return DropSummary(title: String(localized: "一览打不开这种文件"),
                               detail: String(localized: "可以打开 JPEG、PNG、HEIF、RAW、WebP、GIF、SVG、TIFF、MP4、MOV"),
                               acceptable: false)
        }
        let items = (try? FolderScanner.scan(folder: url.deletingLastPathComponent())) ?? []
        return DropSummary(title: String(localized: "松开以打开“\(url.lastPathComponent)”"), detail: counts(items, inParentFolder: true), acceptable: true)
    }

    private static func counts(_ items: [MediaItem], inParentFolder: Bool = false) -> String {
        let videos = items.lazy.filter { $0.kind == .video }.count
        return countText(images: items.count - videos, videos: videos, inParentFolder: inParentFolder)
    }
}
