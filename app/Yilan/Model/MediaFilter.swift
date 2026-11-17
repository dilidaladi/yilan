import Foundation

/// 顶部类型切换：全部 / 图片 / 视频
enum MediaFilter: String, CaseIterable, Sendable, Identifiable {
    case all
    case images
    case videos

    var id: String { rawValue }

    /// 顶部分段控件上的名字
    var title: LocalizedStringResource {
        switch self {
        case .all: "全部"
        case .images: "图片"
        case .videos: "视频"
        }
    }

    /// 分段控件的悬停提示（带快捷键）
    var help: LocalizedStringResource {
        switch self {
        case .all: "全部（⌘1）"
        case .images: "图片（⌘2）"
        case .videos: "视频（⌘3）"
        }
    }

    /// 读屏软件读出的分段名字和数量
    func accessibilityLabel(count: Int) -> String {
        switch self {
        case .all: String(localized: "全部，\(count) 个", comment: "顶部分段控件的读屏文字：全部文件的数量")
        case .images: String(localized: "图片，\(count) 个", comment: "顶部分段控件的读屏文字：图片数量")
        case .videos: String(localized: "视频，\(count) 个", comment: "顶部分段控件的读屏文字：视频数量")
        }
    }

    /// 切换类型后顶部提示条的文字，例如“只看视频 · 4 个”
    func toastText(count: Int) -> String {
        switch self {
        case .all: String(localized: "全部 · \(count) 个", comment: "切换到“全部”后的提示条")
        case .images: String(localized: "只看图片 · \(count) 个", comment: "切换到“只看图片”后的提示条")
        case .videos: String(localized: "只看视频 · \(count) 个", comment: "切换到“只看视频”后的提示条")
        }
    }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .images: "photo"
        case .videos: "video"
        }
    }

    func includes(_ item: MediaItem) -> Bool {
        switch self {
        case .all: true
        case .images: item.kind == .image
        case .videos: item.kind == .video
        }
    }

    func apply(_ items: [MediaItem]) -> [MediaItem] {
        self == .all ? items : items.filter(includes)
    }

    static let defaultsKey = "mediaFilter"
}

enum FilterSelection {
    /// 切换类型后应该选中哪一个：
    /// 当前文件仍在新列表里 → 停在原位；否则 → 跳到在完整列表里离它最近的一个（距离相同时取后面那个）。
    /// - Parameters:
    ///   - current: 切换前选中的文件
    ///   - all: 文件夹里的完整列表（已排序）
    ///   - newList: 切换后的列表（all 的子序列）
    /// - Returns: newList 里的下标；newList 为空时返回 nil
    static func index(keeping current: MediaItem?, in all: [MediaItem], newList: [MediaItem]) -> Int? {
        guard !newList.isEmpty else { return nil }
        guard let current else { return 0 }
        if let same = newList.firstIndex(of: current) { return same }
        guard let anchor = all.firstIndex(of: current) else { return 0 }

        // 完整列表里每一项的位置，用来计算距离
        var position: [URL: Int] = [:]
        position.reserveCapacity(all.count)
        for (i, item) in all.enumerated() { position[item.url] = i }

        var best = 0
        var bestDistance = Int.max
        var bestIsAfter = false
        for (i, item) in newList.enumerated() {
            guard let p = position[item.url] else { continue }
            let d = abs(p - anchor)
            let isAfter = p > anchor
            if d < bestDistance || (d == bestDistance && isAfter && !bestIsAfter) {
                best = i
                bestDistance = d
                bestIsAfter = isAfter
            }
        }
        return best
    }
}
