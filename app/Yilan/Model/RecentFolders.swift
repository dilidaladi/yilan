import Foundation
import Observation

/// 最近打开的文件夹（欢迎界面“最近打开”、菜单“打开最近使用”）
struct RecentFolder: Codable, Hashable, Sendable, Identifiable {
    /// 文件夹路径
    var path: String
    /// 用来显示缩略图的文件（上次停留的那个）
    var coverPath: String?
    var itemCount: Int
    var openedAt: Date

    var id: String { path }
    var url: URL { URL(fileURLWithPath: path) }
    var name: String { url.lastPathComponent }
    /// 主目录显示成 ~，例如 ~/Pictures/2026 秋 · 旅行
    var displayPath: String { (path as NSString).abbreviatingWithTildeInPath }
}

@MainActor
@Observable
final class RecentFolders {
    static let shared = RecentFolders(defaults: AppDefaults.store)
    static let defaultsKey = "recentFolders"
    static let limit = 10

    private(set) var folders: [RecentFolder]
    @ObservationIgnored private let defaults: UserDefaults
    /// 文件夹还在不在：在后台检查后记在这里，界面读取时不碰磁盘（文件夹可能在断开或很慢的网络盘上）
    private var availability: [String: Bool] = [:]
    /// 已挂载的卷（/Volumes/…）；没挂载的卷上的文件夹直接算不在，不去访问磁盘
    @ObservationIgnored private var mountedVolumes: Set<String>
    @ObservationIgnored private var lastRefresh: ContinuousClock.Instant?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    /// 缓存的检查结果多久之后重新检查
    static let refreshInterval: Duration = .seconds(3)

    init(defaults: UserDefaults) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([RecentFolder].self, from: data) {
            folders = saved
        } else {
            folders = []
        }
        // 只读内核里的挂载表，不访问任何磁盘
        mountedVolumes = Self.mountedVolumeRoots()
        scheduleRefresh()
    }

    /// 记一次打开：同一个文件夹只保留一条并移到最前，最多保留 limit 条
    func record(folder: URL, cover: URL?, itemCount: Int, at date: Date = Date()) {
        let path = folder.standardizedFileURL.path
        folders.removeAll { $0.path == path }
        folders.insert(RecentFolder(path: path, coverPath: cover?.standardizedFileURL.path, itemCount: itemCount, openedAt: date), at: 0)
        if folders.count > Self.limit { folders.removeLast(folders.count - Self.limit) }
        availability[path] = true   // 刚打开过，肯定还在
        save()
    }

    /// 更新封面（浏览时停留的文件），不改变顺序
    func updateCover(folder: URL, cover: URL) {
        let path = folder.standardizedFileURL.path
        let coverPath = cover.standardizedFileURL.path
        guard let i = folders.firstIndex(where: { $0.path == path }), folders[i].coverPath != coverPath else { return }
        folders[i].coverPath = coverPath
        save()
    }

    func remove(_ folder: RecentFolder) {
        folders.removeAll { $0.path == folder.path }
        save()
    }

    func clear() {
        folders.removeAll()
        save()
    }

    /// 还存在的文件夹（被删掉或移走的不显示）。只读缓存，不碰磁盘；缓存过期时在后台重新检查
    func existing(limit: Int = RecentFolders.limit) -> [RecentFolder] {
        if lastRefresh.map({ ContinuousClock.now - $0 > Self.refreshInterval }) ?? true { scheduleRefresh() }
        return Array(folders.lazy.filter { self.isAvailable($0.path) }.prefix(limit))
    }

    private func isAvailable(_ path: String) -> Bool {
        if let known = availability[path] { return known }
        // 还没检查过：所在的卷没挂载就算不在，否则先显示，检查完再更新
        return !Self.isOnUnmountedVolume(path, mounted: mountedVolumes)
    }

    private func scheduleRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { await refreshAvailability() }
    }

    /// 在后台检查每个文件夹还在不在
    func refreshAvailability() async {
        lastRefresh = .now
        let paths = folders.map(\.path)
        let (mounted, result) = await Task.detached(priority: .utility) {
            let mounted = RecentFolders.mountedVolumeRoots()
            var result: [String: Bool] = [:]
            for path in paths {
                if RecentFolders.isOnUnmountedVolume(path, mounted: mounted) {
                    result[path] = false
                } else {
                    var isDir: ObjCBool = false
                    result[path] = FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
                }
            }
            return (mounted, result)
        }.value
        mountedVolumes = mounted
        // 没变化就不写，避免界面无谓刷新
        let merged = availability.merging(result) { $1 }
        if merged != availability { availability = merged }
        refreshTask = nil
    }

    /// 挂载表里所有的挂载点（getfsstat，不访问磁盘）
    nonisolated static func mountedVolumeRoots() -> Set<String> {
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: []) ?? []
        return Set(urls.map { $0.standardizedFileURL.path })
    }

    /// 路径在 /Volumes/<卷名> 下，而这个卷没有挂载
    nonisolated static func isOnUnmountedVolume(_ path: String, mounted: Set<String>) -> Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count >= 2, parts[0] == "Volumes" else { return false }
        let root = "/Volumes/\(parts[1])"
        guard !mounted.contains(root) else { return false }
        // /Volumes 里系统盘的名字是指向 / 的替身，不是挂载点（只看 /Volumes 目录本身，不进入卷）
        let target = try? FileManager.default.destinationOfSymbolicLink(atPath: root)
        return target == nil
    }

    private func save() {
        if let data = try? JSONEncoder().encode(folders) { defaults.set(data, forKey: Self.defaultsKey) }
    }
}
