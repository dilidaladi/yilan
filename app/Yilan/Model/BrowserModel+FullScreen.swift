import AppKit
import SwiftUI

/// 全屏（设计稿 08 · 全屏）：静止时只有图片；鼠标碰到顶边出现标题栏控件，进入底部 120 点出现缩略图栏
extension BrowserModel {
    /// 底部感应区高度
    static let fullScreenBottomZone: CGFloat = 120
    /// 顶部控件出现后，鼠标离开这个区域才收起
    static let fullScreenTopZone: CGFloat = 86

    /// 记下主窗口，跟踪全屏和键盘焦点
    func attach(window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        windowObservers.forEach(NotificationCenter.default.removeObserver)
        windowObservers.removeAll()
        let names: [Notification.Name] = [
            NSWindow.willEnterFullScreenNotification, NSWindow.didExitFullScreenNotification,
            NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification,
        ]
        for name in names {
            windowObservers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { note in
                let name = note.name
                MainActor.assumeIsolated { BrowserModel.shared.windowEvent(name) }
            })
        }
        mainWindowIsKey = window.isKeyWindow || NSApp.keyWindow == nil
        isFullScreen = window.styleMask.contains(.fullScreen)
    }

    private func windowEvent(_ name: Notification.Name) {
        switch name {
        case NSWindow.willEnterFullScreenNotification: fullScreenChanged(true)
        case NSWindow.didExitFullScreenNotification: fullScreenChanged(false)
        default: mainWindowIsKey = window?.isKeyWindow ?? false
        }
    }

    /// F、菜单“显示 › 进入全屏幕”
    func toggleFullScreen() {
        guard pendingDelete == nil, let window else { return }
        window.toggleFullScreen(nil)
    }

    private func fullScreenChanged(_ fullScreen: Bool) {
        isFullScreen = fullScreen
        fullScreenBottomTask?.cancel()
        fullScreenBottomTask = nil
        fullScreenIdleTask?.cancel()
        fullScreenHoveringDock = false
        fullScreenTopRevealed = ShotHooks.fullScreenState == "top"
        fullScreenBottomRevealed = ShotHooks.fullScreenState == "bottom"
        fullScreenArrowsVisible = ShotHooks.fullScreenState == "bottom" || ShotHooks.fullScreenState == "top"
    }

    /// 全屏时鼠标移动。yFromTop：鼠标到窗口顶边的距离；height：窗口内容高度
    func fullScreenMouseMoved(yFromTop: CGFloat, height: CGFloat) {
        guard isFullScreen, ShotHooks.fullScreenState == nil else { return }
        // 顶部：碰到顶边出现，离开顶部 86 点后收起
        if yFromTop <= 2 {
            setFullScreenTop(true)
        } else if yFromTop > Self.fullScreenTopZone {
            setFullScreenTop(false)
        }
        // 底部：进入 120 点出现；离开 1 秒后收起，鼠标停在栏上不收起
        if yFromTop >= height - Self.fullScreenBottomZone {
            fullScreenBottomTask?.cancel()
            fullScreenBottomTask = nil
            setFullScreenBottom(true)
        } else if fullScreenBottomRevealed, fullScreenBottomTask == nil, !fullScreenHoveringDock {
            fullScreenBottomTask = Task {
                try? await Task.sleep(for: .seconds(1))
                fullScreenBottomTask = nil
                guard !Task.isCancelled, !fullScreenHoveringDock else { return }
                setFullScreenBottom(false)
            }
        }
        // 箭头：鼠标在动时淡入，静止 2 秒淡出，指针也一起隐藏
        if !fullScreenArrowsVisible {
            withAnimation(.easeOut(duration: 0.2)) { fullScreenArrowsVisible = true }
        }
        fullScreenIdleTask?.cancel()
        fullScreenIdleTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, isFullScreen, !fullScreenHoveringDock, !fullScreenTopRevealed else { return }
            withAnimation(.easeOut(duration: 0.35)) { fullScreenArrowsVisible = false }
            if pendingDelete == nil, !infoVisible { NSCursor.setHiddenUntilMouseMoves(true) }
        }
    }

    /// 鼠标在全屏的缩略图栏或视频控制条上
    func setFullScreenDockHover(_ hovering: Bool) {
        fullScreenHoveringDock = hovering
        if hovering {
            fullScreenBottomTask?.cancel()
            fullScreenBottomTask = nil
        }
    }

    private func setFullScreenTop(_ revealed: Bool) {
        guard revealed != fullScreenTopRevealed else { return }
        withAnimation(.easeOut(duration: 0.25)) { fullScreenTopRevealed = revealed }
    }

    private func setFullScreenBottom(_ revealed: Bool) {
        guard revealed != fullScreenBottomRevealed else { return }
        withAnimation(.easeOut(duration: 0.25)) { fullScreenBottomRevealed = revealed }
    }
}
