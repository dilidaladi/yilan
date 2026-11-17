import SwiftUI

/// 视频控制条（设计稿 .vbar）：高 46，常规玻璃胶囊；播放键、当前时间、进度条、总时长、循环、音量
struct VideoControlBar: View {
    let video: VideoPlayerController
    @Bindable var settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            Button(action: video.togglePlay) {
                Image(systemName: video.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.2)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(video.isPlaying ? "暂停（空格）" : "播放（空格）")
            .accessibilityLabel(video.isPlaying ? "暂停" : "播放")

            Text(verbatim: Formatting.clock(video.currentTime))
                .font(Theme.mono(11.5))
                .foregroundStyle(.white)
                .monospacedDigit()

            ScrubTrack(video: video)

            Text(verbatim: Formatting.duration(video.duration))
                .font(Theme.mono(11.5))
                .foregroundStyle(Theme.text2)

            Button { settings.loopVideo.toggle() } label: {
                Image(systemName: "repeat")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(settings.loopVideo ? Color.white : Theme.text2)
                    .frame(width: 18, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(settings.loopVideo ? "循环播放：开" : "循环播放：关")
            .accessibilityLabel("循环播放")
            .accessibilityValue(settings.loopVideo ? "开" : "关")

            HStack(spacing: 8) {
                Button(action: video.toggleMute) {
                    Image(systemName: video.isMuted || video.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.text2)
                        .frame(width: 20, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(video.isMuted ? "取消静音（M）" : "静音（M）")
                .accessibilityLabel(video.isMuted ? "取消静音" : "静音")
                VolumeSlider(video: video)
            }
        }
        .padding(.leading, 7)
        .padding(.trailing, 14)
        .frame(height: 46)
        .regularGlass(Capsule())
    }
}

/// 进度条：高 5，已缓冲浅色、已播放白色、13pt 圆点；悬停或拖动时上方显示时间
struct ScrubTrack: View {
    let video: VideoPlayerController
    @State private var hoverX: CGFloat?
    @State private var dragX: CGFloat?

    var body: some View {
        GeometryReader { geo in
            let w = max(1, geo.size.width)
            let played = dragX.map { $0 / w } ?? VideoTransport.fraction(of: video.currentTime, duration: video.duration)
            let buffered = VideoTransport.fraction(of: video.bufferedTime, duration: video.duration)
            let tipX = dragX ?? hoverX ?? ShotHooks.hoverFraction.map { $0 * w }
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.2))
                Capsule().fill(Color.white.opacity(0.28)).frame(width: w * buffered)
                Capsule().fill(Color.white).frame(width: w * played)
                Circle()
                    .fill(.white)
                    .frame(width: 13, height: 13)
                    .shadow(color: .black.opacity(0.45), radius: 2.5, y: 1)
                    .offset(x: w * played - 6.5)
            }
            .frame(height: 5)
            .frame(maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                if let x = tipX {
                    let t = VideoTransport.time(atFraction: x / w, duration: video.duration)
                    ScrubTooltip(text: Formatting.clock(t))
                        .fixedSize()
                        .position(x: min(max(x, 0), w), y: geo.size.height / 2 - 23)   // 气泡底边距进度条底边 16
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let p): hoverX = min(max(p.x, 0), w)
                case .ended: hoverX = nil
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let x = min(max(g.location.x, 0), w)
                        if dragX == nil { video.beginScrub() }
                        dragX = x
                        video.scrub(toFraction: x / w)
                    }
                    .onEnded { g in
                        let x = min(max(g.location.x, 0), w)
                        video.endScrub(atFraction: x / w)
                        dragX = nil
                    }
            )
        }
        .frame(height: 28)
        .accessibilityElement()
        .accessibilityLabel("播放进度")
        .accessibilityValue(Text(verbatim: "\(Formatting.clock(video.currentTime)) / \(Formatting.clock(video.duration))"))
        .accessibilityAdjustableAction { direction in
            video.skip(by: direction == .increment ? VideoTransport.skipSeconds : -VideoTransport.skipSeconds)
        }
    }
}

/// 进度条上方的时间气泡（设计稿 .tip：厚玻璃，圆角 7）
struct ScrubTooltip: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Theme.mono(11))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .thickGlass(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

/// 音量条（设计稿 .vol：56 × 4）
struct VolumeSlider: View {
    let video: VideoPlayerController

    var body: some View {
        GeometryReader { geo in
            let level = video.isMuted ? 0 : CGFloat(video.volume)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.2))
                Capsule().fill(Color.white.opacity(0.85)).frame(width: geo.size.width * level)
            }
            .frame(height: 4)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { g in
                    video.volume = Float(min(max(g.location.x / geo.size.width, 0), 1))
                }
            )
        }
        .frame(width: 56, height: 20)
        .accessibilityElement()
        .accessibilityLabel("音量")
        .accessibilityValue(Text(verbatim: Double(video.isMuted ? 0 : video.volume).formatted(.percent.precision(.fractionLength(0)))))
        .accessibilityAdjustableAction { direction in
            video.volume = min(1, max(0, video.volume + (direction == .increment ? 0.1 : -0.1)))
        }
    }
}
