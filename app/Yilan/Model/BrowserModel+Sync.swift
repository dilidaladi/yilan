import SwiftUI

/// 文件夹变化同步（设计稿 08 · 文件夹变化同步）
extension BrowserModel {
    func startWatching(_ folder: URL) {
        stopWatching()
        // 跑单元测试时一览是宿主程序：测试自己会直接调用 applySync
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        watcher = FolderWatcher(folder: folder) { [weak self] in self?.folderDidChange() }
    }

    func stopWatching() {
        watcher?.stop()
        watcher = nil
        syncTask?.cancel()
        syncTask = nil
    }

    /// 文件夹有变化：等 0.3 秒（期间又有变化就再等），合并成一次重新扫描
    func folderDidChange() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let folder = folderURL else { return }
            let serial = localChangeSerial
            let scanned = await Task.detached(priority: .utility) { try? FolderScanner.scan(folder: folder) }.value
            guard !Task.isCancelled, folder == folderURL, let scanned else { return }
            // 扫描期间一览自己删除或恢复了文件：结果可能已经过时，重新扫一次
            if serial != localChangeSerial || trashBusy {
                folderDidChange()
                return
            }
            applySync(scanned)
        }
    }

    /// 用新的扫描结果更新列表（测试里直接调用）。
    /// 当前文件还在就不动；被改名时继续显示它；被删除或移走时显示相邻的一个
    func applySync(_ scanned: [MediaItem]) {
        let diff = FolderDiff(old: allItems, new: scanned)
        guard !diff.isEmpty else { return }
        forgetCaches(for: diff.changedURLs)

        var target = current
        var replacement: (item: MediaItem, isNext: Bool)?
        var currentGone = false
        if let cur = current {
            if let same = scanned.first(where: { $0.url == cur.url }) {
                target = same                      // 还在（内容变了时会原地重新加载）
            } else if let renamed = diff.renamed[cur] {
                target = renamed                   // 改名：视为同一个文件，不提示
            } else {
                currentGone = true
                replacement = SyncSelection.replacement(for: cur, oldList: items, newList: filter.apply(scanned))
                target = replacement?.item
            }
        }
        replaceItems(scanned, showing: target)

        if currentGone {
            let detail: String? = switch replacement?.isNext {
            case true?: String(localized: "已显示下一个")
            case false?: String(localized: "已显示上一个")
            case nil: nil
            }
            showToast(symbol: "info.circle", text: String(localized: "当前文件已被删除或移走"), detail: detail, duration: 4)
        } else if !diff.added.isEmpty {
            showToast(symbol: "folder", text: String(localized: "新增 \(diff.added.count) 个文件"), duration: 3)
        }
        markFresh(diff.added.map(\.url))
    }

    /// 新文件的缩略图高亮 2 秒，然后淡回普通样式
    private func markFresh(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        freshURLs.formUnion(urls)
        freshTask?.cancel()
        freshTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.6)) { freshURLs = [] }
        }
    }
}
