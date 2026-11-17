import CoreGraphics
import Testing
@testable import Yilan

@Suite("窗口位置修正")
struct WindowPlacementTests {
    // 主屏幕 1440 × 900（可用区域去掉菜单栏和程序坞），右边接一块 1920 × 1080 的外接屏
    let main = CGRect(x: 0, y: 80, width: 1440, height: 795)
    let external = CGRect(x: 1440, y: 0, width: 1920, height: 1055)

    @Test("在屏幕里的窗口不动")
    func onScreenUnchanged() {
        let frame = CGRect(x: 100, y: 100, width: 1280, height: 700)
        #expect(WindowPlacement.corrected(frame: frame, visibleFrames: [main], mainVisibleFrame: main) == nil)
        // 窗口大部分在屏幕外，但标题栏还有一段能抓住
        let mostlyOff = CGRect(x: 1300, y: 100, width: 1280, height: 700)
        #expect(WindowPlacement.corrected(frame: mostlyOff, visibleFrames: [main], mainVisibleFrame: main) == nil)
        // 在外接屏上
        let onExternal = CGRect(x: 1600, y: 100, width: 1280, height: 800)
        #expect(WindowPlacement.corrected(frame: onExternal, visibleFrames: [main, external], mainVisibleFrame: main) == nil)
    }

    @Test("外接屏断开后，窗口移回主屏幕中间，大小不变")
    func externalDisconnected() throws {
        let onExternal = CGRect(x: 1600, y: 100, width: 1280, height: 700)
        let fixed = try #require(WindowPlacement.corrected(frame: onExternal, visibleFrames: [main], mainVisibleFrame: main))
        #expect(fixed.size == onExternal.size)
        #expect(fixed.midX == main.midX)
        #expect(abs(fixed.midY - main.midY) <= 0.5)
    }

    @Test("标题栏被挪到屏幕上沿外面也要修正")
    func titleBarAboveScreen() throws {
        let above = CGRect(x: 100, y: 860, width: 1000, height: 600)   // 标题栏在可用区域上方
        #expect(WindowPlacement.corrected(frame: above, visibleFrames: [main], mainVisibleFrame: main) != nil)
        let sliver = CGRect(x: 1400, y: 100, width: 1000, height: 600)   // 只剩 40pt 宽的一段
        #expect(WindowPlacement.corrected(frame: sliver, visibleFrames: [main], mainVisibleFrame: main) != nil)
    }

    @Test("比主屏幕大的窗口缩小到主屏幕可用区域，但不小于最小尺寸")
    func clampedToMainScreen() throws {
        let huge = CGRect(x: 4000, y: 0, width: 2560, height: 1400)
        let fixed = try #require(WindowPlacement.corrected(frame: huge, visibleFrames: [main], mainVisibleFrame: main,
                                                            minSize: CGSize(width: 640, height: 440)))
        #expect(fixed == main)
        let small = CGRect(x: 2000, y: 0, width: 300, height: 200)
        let grown = try #require(WindowPlacement.corrected(frame: small, visibleFrames: [main], mainVisibleFrame: main,
                                                            minSize: CGSize(width: 640, height: 440)))
        #expect(grown.size == CGSize(width: 640, height: 440))
    }
}
