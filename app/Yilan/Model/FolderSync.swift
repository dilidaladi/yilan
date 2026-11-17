import CoreServices
import Foundation

/// 两次扫描之间文件夹的变化
struct FolderDiff: Equatable {
    /// 新出现的文件（不含改名后的）
    var added: [MediaItem] = []
    /// 不见了的文件（不含改名前的）
    var removed: [MediaItem] = []
    /// 同一路径，内容变了（新版本）
    var modified: [MediaItem] = []
    /// 改名：旧 → 新（同一个文件编号）
    var renamed: [MediaItem: MediaItem] = [:]

    init(old: [MediaItem], new: [MediaItem]) {
        let oldByPath = Dictionary(old.map { ($0.url.path, $0) }, uniquingKeysWith: { a, _ in a })
        let newByPath = Dictionary(new.map { ($0.url.path, $0) }, uniquingKeysWith: { a, _ in a })
        var gone = old.filter { newByPath[$0.url.path] == nil }
        var appeared = new.filter { oldByPath[$0.url.path] == nil }
        modified = new.filter { n in
            guard let o = oldByPath[n.url.path] else { return false }
            return o.modificationDate != n.modificationDate || o.fileSize != n.fileSize
        }
        for g in gone {
            guard let id = g.fileID, let i = appeared.firstIndex(where: { $0.fileID == id }) else { continue }
            renamed[g] = appeared.remove(at: i)
        }
        gone.removeAll { renamed[$0] != nil }
        added = appeared
        removed = gone
    }

    var isEmpty: Bool { added.isEmpty && removed.isEmpty && modified.isEmpty && renamed.isEmpty }

    /// 所有受影响的路径（清缓存用）
    var changedURLs: Set<URL> {
        var urls = Set((added + removed + modified).map(\.url))
        for (from, to) in renamed { urls.insert(from.url); urls.insert(to.url) }
        return urls
    }
}

/// 当前文件被删除或移走后显示哪一个
enum SyncSelection {
    /// 在旧列表里从当前项往后找第一个还在的；后面都没了就往前找。
    /// 返回新版本的文件和是否是“下一个”
    static func replacement(for current: MediaItem, oldList: [MediaItem], newList: [MediaItem]) -> (item: MediaItem, isNext: Bool)? {
        let newByPath = Dictionary(newList.map { ($0.url.path, $0) }, uniquingKeysWith: { a, _ in a })
        guard let i = oldList.firstIndex(of: current) else { return newList.first.map { ($0, true) } }
        for j in oldList.indices where j > i {
            if let n = newByPath[oldList[j].url.path] { return (n, true) }
        }
        for j in oldList.indices.reversed() where j < i {
            if let n = newByPath[oldList[j].url.path] { return (n, false) }
        }
        return newList.first.map { ($0, true) }
    }
}

/// 监听文件夹（FSEvents，0.3 秒合并一次）。只关心这一层的增、删、改名、修改，子文件夹里的变化忽略
@MainActor
final class FolderWatcher {
    nonisolated(unsafe) private var stream: FSEventStreamRef?
    private let folderPath: String
    private let onChange: @MainActor () -> Void

    init?(folder: URL, onChange: @escaping @MainActor () -> Void) {
        // FSEvents 报的是真实路径（/tmp → /private/tmp），这里也取真实路径来比较
        guard let real = realpath(folder.path, nil) else { return nil }
        let realPath = String(cString: real)
        free(real)
        folderPath = realPath.lowercased()
        self.onChange = onChange
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                           retain: nil, release: nil, copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, count, paths, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()
            let list = (unsafeBitCast(paths, to: NSArray.self) as? [String]) ?? []
            // 回调在主队列上（见 FSEventStreamSetDispatchQueue）
            MainActor.assumeIsolated { watcher.handle(list) }
        }
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
                                             | kFSEventStreamCreateFlagWatchRoot)
        guard let stream = FSEventStreamCreate(nil, callback, &context, [realPath] as CFArray,
                                               FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.3, flags)
        else { return nil }
        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
        self.stream = stream
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    private func handle(_ paths: [String]) {
        let relevant = paths.contains { path in
            let p = path.lowercased()
            return p == folderPath || (p as NSString).deletingLastPathComponent == folderPath
        }
        if relevant { onChange() }
    }
}
