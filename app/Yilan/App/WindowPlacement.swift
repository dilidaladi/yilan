import AppKit

/// 窗口位置检查：上次保存的位置在已经断开的显示器上（或被挪到屏幕外）时，
/// 标题栏抓不到，窗口等于“丢了”。这时把窗口按原大小（放不下就缩小）移到主屏幕中间
enum WindowPlacement {
    /// 标题栏至少要有这么宽的一段落在某块屏幕的可用区域里，才算能抓住拖动
    static let minimumGrabWidth: CGFloat = 100
    /// 标题栏高度（只检查这一条是否可见）
    static let titleBarHeight: CGFloat = 28

    /// 纯函数：返回修正后的窗口位置；位置没问题时返回 nil。
    /// 坐标都是 AppKit 的屏幕坐标（原点在左下）
    static func corrected(frame: CGRect, visibleFrames: [CGRect], mainVisibleFrame: CGRect,
                          minSize: CGSize = .zero) -> CGRect? {
        guard !mainVisibleFrame.isEmpty else { return nil }
        let titleBar = CGRect(x: frame.minX, y: frame.maxY - titleBarHeight, width: frame.width, height: titleBarHeight)
        let needed = min(minimumGrabWidth, frame.width)
        let grabbable = visibleFrames.contains { screen in
            let overlap = titleBar.intersection(screen)
            // 标题栏整条高度都要在屏幕里：上沿被菜单栏挡住也抓不到
            return !overlap.isNull && overlap.width >= needed && overlap.height >= titleBarHeight - 1
        }
        if grabbable { return nil }
        // 大小保持，超过主屏幕可用区域时缩小，但不小于窗口最小尺寸
        let width = max(min(frame.width, mainVisibleFrame.width), min(minSize.width, mainVisibleFrame.width))
        let height = max(min(frame.height, mainVisibleFrame.height), min(minSize.height, mainVisibleFrame.height))
        return CGRect(x: (mainVisibleFrame.midX - width / 2).rounded(),
                      y: (mainVisibleFrame.midY - height / 2).rounded(),
                      width: width, height: height)
    }

    /// 检查并修正窗口位置（启动、窗口恢复、显示器断开时调用）
    @MainActor
    static func ensureOnScreen(_ window: NSWindow) {
        guard !window.styleMask.contains(.fullScreen),
              let main = NSScreen.screens.first ?? NSScreen.main else { return }
        let frames = NSScreen.screens.map(\.visibleFrame)
        guard let fixed = corrected(frame: window.frame, visibleFrames: frames,
                                    mainVisibleFrame: main.visibleFrame, minSize: window.minSize) else { return }
        Log.app.info("窗口不在任何屏幕上，移回主屏幕中间")
        window.setFrame(fixed, display: true)
    }
}
