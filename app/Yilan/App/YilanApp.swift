import AppKit
import OSLog
import SwiftUI

enum Log {
    static let app = Logger(subsystem: "com.yilan.viewer", category: "app")
}

@main
struct YilanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // 命令行参数里的文件路径默认会被 AppKit 当作“打开文件”事件，这时 SwiftUI 不创建主窗口；
        // 关掉这个行为，改由 applicationDidFinishLaunching 自己读参数
        UserDefaults.standard.register(defaults: ["NSTreatUnknownArgumentsAsOpen": "NO"])
        // 要在显示任何文字之前：系统语言不是中文也不是英文时改用英文
        LanguageSettings.applyFallbackAtLaunch()
    }

    var body: some Scene {
        Window("一览", id: "main") {
            RootView()
                .frame(minWidth: 640, minHeight: 440)
        }
        .windowStyle(.hiddenTitleBar)
        // 单窗口场景默认会“记住”上次被关掉，导致下次启动没有窗口；每次启动都打开主窗口
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.presented)
        .defaultSize(width: 1280, height: 800)
        .windowResizability(.contentMinSize)
        .commands { AppCommands() }

        // 设置（⌘,）：设计稿 05 · 设置

    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// 访达“打开方式”、拖到程序坞图标、`open -a` 打开的文件
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        BrowserModel.shared.open(url)
    }

    func applicationWillTerminate(_ notification: Notification) {
        BrowserModel.shared.saveRecentCover()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Perf.mark("didFinishLaunching")
        MemoryPressureMonitor.start()
        // 缩略图磁盘缓存：后台清理太旧的、超出上限的
        Task.detached(priority: .background) { ThumbnailGenerator.prune() }
        // 调试用：命令行参数里的路径（`Yilan.app/Contents/MacOS/Yilan /path/to/file`）
        let args = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }
        if let path = args.first, FileManager.default.fileExists(atPath: path), !BrowserModel.shared.hasOpenedFolder {
            BrowserModel.shared.open(URL(fileURLWithPath: path))
        }
        // 访达“打开方式”的文件在这之前已经送到；稍等一下再决定要不要打开上次的文件夹
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            BrowserModel.shared.reopenLastFolderIfNeeded()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// 菜单栏：文件 / 显示 / 前往（设计稿 05 系统界面）
struct AppCommands: Commands {
    private var model: BrowserModel { BrowserModel.shared }

    var body: some Commands {
        // 设置窗口由 AppKit 承载（见 SettingsWindow），菜单项自己接
        CommandGroup(replacing: .appSettings) {
            Button("设置…") { SettingsWindow.shared.show() }
                .keyboardShortcut(",", modifiers: .command)
        }
        CommandGroup(replacing: .newItem) {
            Button("打开…") { model.showOpenPanel() }
                .keyboardShortcut("o")
            Menu("打开最近使用") {
                let recents = model.recents.existing()
                ForEach(recents) { folder in
                    Button(folder.name) { model.open(folder.url) }
                }
                if !recents.isEmpty { Divider() }
                Button("清除菜单") { model.recents.clear() }
                    .disabled(recents.isEmpty)
            }
        }
        CommandGroup(after: .newItem) {
            Divider()
            Button("在访达中显示") { model.revealCurrentInFinder() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            Button("拷贝文件路径") { model.copyCurrentPath() }
                .keyboardShortcut("c", modifiers: [.command, .option])
            Divider()
            Button("向右旋转") { model.rotate(1) }
                .keyboardShortcut("r", modifiers: [])
                .disabled(model.current == nil)
            Button("向左旋转") { model.rotate(-1) }
                .keyboardShortcut("r", modifiers: [.shift])
                .disabled(model.current == nil)
            Divider()
            // 只在主窗口在前时可用：设置窗口的输入框里按 ⌫ 是删字
            Button("移到废纸篓") { model.requestDelete() }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(!model.canDelete)
        }
        // 编辑 › 撤销“移到废纸篓”（⌘Z）。设置窗口在前时交给输入框自己撤销
        CommandGroup(replacing: .undoRedo) {
            Button(model.canUndoDelete && model.mainWindowIsKey ? "撤销“移到废纸篓”" : "撤销") { model.undoFromMenu() }
                .keyboardShortcut("z")
                .disabled(model.mainWindowIsKey && !model.canUndoDelete)
            Button("重做") { model.redoFromMenu() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(model.mainWindowIsKey)
        }
        CommandGroup(before: .toolbar) {
            filterToggle("全部", .all, key: "1")
            filterToggle("只看图片", .images, key: "2")
            filterToggle("只看视频", .videos, key: "3")
            Divider()
            Button("适应窗口") { model.zoom(.fit) }.keyboardShortcut("0", modifiers: [])
            Button("实际大小") { model.zoom(.actualSize) }.keyboardShortcut("1", modifiers: [])
            Button("放大") { model.zoom(.zoomIn) }.keyboardShortcut("+")
            Button("缩小") { model.zoom(.zoomOut) }.keyboardShortcut("-")
            Divider()
            Toggle("缩略图栏", isOn: Binding(
                get: { model.stripVisible },
                set: { visible in withAnimation(.easeInOut(duration: 0.25)) { model.stripVisible = visible } }
            ))
            .keyboardShortcut("t", modifiers: [])
            Toggle("信息面板", isOn: Binding(
                get: { model.infoVisible },
                set: { model.setInfoVisible($0) }
            ))
            .keyboardShortcut("i", modifiers: [])
            .disabled(model.current == nil || !model.mainWindowIsKey)
            Divider()
            Button(model.isFullScreen ? "退出全屏幕" : "进入全屏幕") { model.toggleFullScreen() }
                .keyboardShortcut("f", modifiers: [])
                .disabled(!model.mainWindowIsKey || model.pendingDelete != nil)
            Divider()
        }
        CommandMenu("前往") {
            Button("上一个") { model.previous() }.keyboardShortcut(.upArrow, modifiers: [])
            Button("下一个") { model.next() }.keyboardShortcut(.downArrow, modifiers: [])
            Button("第一个") { model.first() }.keyboardShortcut(.home, modifiers: [])
            Button("最后一个") { model.last() }.keyboardShortcut(.end, modifiers: [])
        }
    }

    /// 带勾选标记的类型菜单项（设计稿“菜单 · 显示”）
    private func filterToggle(_ title: LocalizedStringKey, _ filter: MediaFilter, key: KeyEquivalent) -> some View {
        Toggle(title, isOn: Binding(
            get: { model.filter == filter },
            set: { _ in model.setFilter(filter) }
        ))
        .keyboardShortcut(key)
        .disabled((model.counts[filter] ?? 0) == 0)
    }
}
