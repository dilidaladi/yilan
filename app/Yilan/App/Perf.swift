import AppKit
import OSLog
import QuartzCore

/// 性能测量：冷启动到第一张大图、切换延迟。
/// 始终打 os_signpost（Instruments 里看 “com.yilan.viewer / perf”）；
/// 启动参数带 `--perf` 时在标准输出打印数字，带 `--perf-switches=N` 时自动连续切换 N 次后打印统计并退出。
@MainActor
enum Perf {
    private static let signposter = OSSignposter(subsystem: "com.yilan.viewer", category: "perf")
    static let enabled = CommandLine.arguments.contains { $0 == "--perf" || $0.hasPrefix("--perf-switches=") }
    static let autoSwitches: Int = CommandLine.arguments
        .first { $0.hasPrefix("--perf-switches=") }
        .flatMap { Int($0.split(separator: "=").last ?? "") } ?? 0
    /// 自动切换的间隔（毫秒），默认 250
    static let switchIntervalMs: Int = CommandLine.arguments
        .first { $0.hasPrefix("--perf-interval=") }
        .flatMap { Int($0.split(separator: "=").last ?? "") } ?? 250

    private static var pending: (url: URL, start: CFTimeInterval, state: OSSignpostIntervalState)?
    /// 数据已经解码好、等待贴到画面上的文件
    private static var readyURL: URL?
    private static var firstImageLogged = false
    private static var latencies: [Double] = []
    /// 最近一次选中的文件和时间（RAW 预览 / 完整解码各自计时用）
    private static var selected: (url: URL, start: CFTimeInterval)?

    /// 进程启动到现在的毫秒数（用内核记录的进程启动时间）
    static func msSinceProcessStart() -> Double {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return -1 }
        let start = info.kp_proc.p_starttime
        let startSeconds = Double(start.tv_sec) + Double(start.tv_usec) / 1_000_000
        return (Date().timeIntervalSince1970 - startSeconds) * 1000
    }

    /// 输出到标准输出并立即刷新（重定向到文件时 print 会被缓冲）
    static func out(_ line: String) {
        print(line)
        fflush(stdout)
    }

    static func mark(_ name: StaticString) {
        signposter.emitEvent(name)
        if enabled { out(String(format: "[perf] %@ at %.0f ms since launch", "\(name)", msSinceProcessStart())) }
    }

    /// 开始切换到某个文件
    static func beginSwitch(to url: URL) {
        if let p = pending { signposter.endInterval("switch", p.state, "abandoned") }
        pending = (url, CACurrentMediaTime(), signposter.beginInterval("switch", id: signposter.makeSignpostID()))
        readyURL = nil
        selected = (url, CACurrentMediaTime())
    }

    /// 大图数据准备好（缓存命中或解码完成）
    static func shown(_ url: URL, isPreview: Bool) {
        readyURL = url
        if enabled, let sel = selected, sel.url == url {
            out(String(format: "[perf] %@ %@ ready: %.0f ms after select", url.lastPathComponent,
                       isPreview ? "preview" : "full", (CACurrentMediaTime() - sel.start) * 1000))
        }
    }

    /// 大图区真正换上了这张图（图层内容已设置，下一帧上屏）
    static func displayed(_ url: URL) {
        guard url == readyURL else { return }   // 缩略图占位不算
        readyURL = nil
        if !firstImageLogged {
            firstImageLogged = true
            let ms = msSinceProcessStart()
            signposter.emitEvent("first image")
            if enabled { out(String(format: "[perf] first image on stage: %.0f ms since process start", ms)) }
            pending = nil
            if autoSwitches > 0 { runAutoSwitches() }
            return
        }
        guard let p = pending, p.url == url else { return }
        let ms = (CACurrentMediaTime() - p.start) * 1000
        signposter.endInterval("switch", p.state)
        pending = nil
        latencies.append(ms)
        if enabled { out(String(format: "[perf] switch → %@: %.1f ms", url.lastPathComponent, ms)) }
    }

    /// 自动连续切换（按 → 的效果），结束后打印统计并退出
    private static func runAutoSwitches() {
        Task { @MainActor in
            let model = BrowserModel.shared
            try? await Task.sleep(for: .milliseconds(800))   // 先让前后预加载跑起来
            for _ in 0..<autoSwitches {
                model.next()
                try? await Task.sleep(for: .milliseconds(switchIntervalMs))
            }
            try? await Task.sleep(for: .milliseconds(500))
            let sorted = latencies.sorted()
            if !sorted.isEmpty {
                let p = { (q: Double) in sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * q))] }
                out(String(format: "[perf] switches=%d  median=%.1f ms  p95=%.1f ms  max=%.1f ms  over100ms=%d",
                             sorted.count, p(0.5), p(0.95), sorted.last!, sorted.filter { $0 > 100 }.count))
            } else {
                out("[perf] no switch measured")
            }
            NSApp.terminate(nil)
        }
    }
}
