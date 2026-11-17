import AppKit
import SwiftUI

/// 信息面板：开关、读取当前文件的信息、拷贝
extension BrowserModel {
    func toggleInfo() { setInfoVisible(!infoVisible) }

    func setInfoVisible(_ visible: Bool) {
        guard visible != infoVisible else { return }
        withAnimation(.easeInOut(duration: 0.25)) { infoVisible = visible }
        if visible { refreshInfo() } else { infoTask?.cancel() }
    }

    /// 面板开着时，读当前文件的信息。读得快就直接换成新内容（不闪）；
    /// 超过 120 毫秒还没读完，先显示“文件”组的基本信息
    func refreshInfo() {
        infoTask?.cancel()
        guard infoVisible, let item = current else {
            if current == nil { info = nil }
            return
        }
        if let cached = metadataCache[item] {
            info = InfoContent.make(cached)
            return
        }
        infoTask = Task {
            let reader = Task.detached(priority: .userInitiated) { await MetadataReader.read(item) }
            let fallback = Task {
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled, item == current, info?.title != item.name else { return }
                info = InfoContent.make(MetadataReader.basic(item))
            }
            let meta = await withTaskCancellationHandler { await reader.value } onCancel: { reader.cancel() }
            fallback.cancel()
            guard !Task.isCancelled, item == current else { return }
            if metadataCache.count > 300 { metadataCache.removeAll() }
            metadataCache[item] = meta
            info = InfoContent.make(meta)
        }
    }

    /// 文件变了（外部修改、删除）：忘掉它的缓存信息
    func forgetMetadata(for urls: Set<URL>) {
        metadataCache = metadataCache.filter { !urls.contains($0.key.url) }
    }

    func copyInfo() {
        guard let info else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info.copyText(), forType: .string)
        showToast(symbol: "doc.on.doc", text: String(localized: "已拷贝"))
    }

    func copyCoordinates() {
        guard let text = info?.coordinates else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        showToast(symbol: "doc.on.doc", text: String(localized: "已拷贝"))
    }
}
