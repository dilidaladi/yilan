import Foundation

/// 信息面板里数值的写法（设计稿 08 · 信息面板）。
/// 摄影参数（f/1.78、1/1250、24mm）按行业惯例写，不随语言变化
enum InfoFormat {
    private static let posix = Locale(identifier: "en_US_POSIX")

    /// 最多 maxDigits 位小数，去掉末尾的 0
    static func decimal(_ value: Double, maxDigits: Int, locale: Locale = posix) -> String {
        value.formatted(.number.precision(.fractionLength(0...maxDigits)).grouping(.never).locale(locale))
    }

    /// 光圈：f/1.78、f/4
    static func aperture(_ f: Double) -> String { "f/" + decimal(f, maxDigits: 2) }

    /// 快门：1/1250、1/3、0.4s、2s、1.5s
    static func shutter(_ seconds: Double) -> String {
        guard seconds > 0 else { return "" }
        if seconds >= 1 { return decimal(seconds, maxDigits: 1) + "s" }
        let inverse = 1 / seconds
        // 1/4 秒以下、或者正好是 1/N 的，写成分数
        if seconds <= 0.25 || abs(inverse - inverse.rounded()) < 0.05 {
            return "1/\(Int(inverse.rounded()))"
        }
        return decimal(seconds, maxDigits: 1) + "s"
    }

    /// 焦距：24mm、4.2mm
    static func focalLength(_ mm: Double) -> String {
        abs(mm - mm.rounded()) < 0.05 ? "\(Int(mm.rounded()))mm" : decimal(mm, maxDigits: 1) + "mm"
    }

    /// 曝光补偿：+0.3 EV、−0.7 EV、0 EV
    static func exposureBias(_ ev: Double) -> String {
        let rounded = (ev * 10).rounded() / 10
        if rounded == 0 { return "0 EV" }
        return (rounded > 0 ? "+" : "−") + decimal(abs(rounded), maxDigits: 1) + " EV"
    }

    /// 度分秒：35°00′41.2″ N
    static func dms(_ value: Double, isLatitude: Bool) -> String {
        let hemisphere = isLatitude ? (value < 0 ? "S" : "N") : (value < 0 ? "W" : "E")
        // 先四舍五入到 0.1 秒再拆分，避免出现 60.0″
        let tenths = Int((abs(value) * 36000).rounded())
        let degrees = tenths / 36000
        let minutes = (tenths % 36000) / 600
        let seconds = Double(tenths % 600) / 10
        let secondsText = (seconds < 10 ? "0" : "") + String(format: "%.1f", locale: posix, seconds)
        return "\(degrees)°\(String(format: "%02d", minutes))′\(secondsText)″ \(hemisphere)"
    }

    /// 拷贝用的坐标：35.011444, 135.772722
    static func coordinates(latitude: Double, longitude: Double) -> String {
        String(format: "%.6f, %.6f", locale: posix, latitude, longitude)
    }

    /// 海拔：48 m、−12 m
    static func altitude(_ meters: Double, locale: Locale = .autoupdatingCurrent) -> String {
        let value = Int(meters.rounded())
        return (value < 0 ? "−" : "") + "\(abs(value).formatted(.number.locale(locale))) m"
    }

    /// 码率：40.4 Mbps、850 kbps
    static func bitrate(_ bitsPerSecond: Double, locale: Locale = .autoupdatingCurrent) -> String {
        if bitsPerSecond >= 1_000_000 {
            return decimal(bitsPerSecond / 1_000_000, maxDigits: 1, locale: locale) + " Mbps"
        }
        return "\(Int((bitsPerSecond / 1000).rounded())) kbps"
    }

    /// 帧率：60.00 fps、29.97 fps
    static func frameRate(_ fps: Double, locale: Locale = .autoupdatingCurrent) -> String {
        fps.formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(locale)) + " fps"
    }

    /// 采样率：48 kHz、44.1 kHz
    static func sampleRate(_ hz: Double, locale: Locale = .autoupdatingCurrent) -> String {
        decimal(hz / 1000, maxDigits: 1, locale: locale) + " kHz"
    }

    private static func fixedFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = posix
        f.dateFormat = format
        return f
    }

    /// 文件的创建、修改时间：2026-10-14 11:20（按本地时区）
    static func dateTime(_ date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let f = fixedFormatter("yyyy-MM-dd HH:mm")
        f.timeZone = timeZone
        return f.string(from: date)
    }

    /// 视频的拍摄时间：2026-10-14 16:02:12（按本地时区）
    static func captureDate(_ date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let f = fixedFormatter("yyyy-MM-dd HH:mm")
        f.timeZone = timeZone
        return f.string(from: date)
    }

    /// EXIF 时间“2026:10:14 11:20:36”→“2026-10-14 11:20”（EXIF 没有时区，照原样显示）
    static func exifDate(_ raw: String) -> String? {
        let parts = raw.trimmingCharacters(in: .whitespaces).split(separator: " ")
        guard parts.count == 2 else { return nil }
        let day = parts[0].split(separator: ":")
        guard day.count == 3, day.allSatisfy({ Int($0) != nil }), day[0] != "0000" else { return nil }
        // 设计稿只显示到分钟（2026-10-12 09:41）
        let time = parts[1].split(separator: ":")
        guard time.count >= 2 else { return day.joined(separator: "-") }
        return "\(day.joined(separator: "-")) \(time[0]):\(time[1])"
    }

    /// 相机名：型号里已经带了厂商名（Canon EOS R10、NIKON Z 6）或是苹果设备时只写型号
    static func cameraName(make: String?, model: String?) -> String? {
        let make = make?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        guard let model = model?.trimmingCharacters(in: .whitespaces).nilIfEmpty else { return make }
        guard let make else { return model }
        let brand = make.split(separator: " ").first.map(String.init) ?? make
        if make.caseInsensitiveCompare("Apple") == .orderedSame || model.localizedCaseInsensitiveContains(brand) {
            return model
        }
        return "\(make) \(model)"
    }

    /// 镜头名：iPhone 的镜头名以机型开头（iPhone 12 Pro back triple camera 4.2mm f/1.6），去掉重复的机型
    static func lensName(_ lens: String, model: String?) -> String {
        let lens = lens.trimmingCharacters(in: .whitespaces)
        guard let model, !model.isEmpty, lens.hasPrefix(model + " ") else { return lens }
        return String(lens.dropFirst(model.count + 1))
    }

    /// 色彩描述文件：sRGB IEC61966-2.1 → sRGB
    static func profileName(_ name: String) -> String {
        name.hasPrefix("sRGB") ? "sRGB" : name
    }

    /// 视频编码的名称
    static func codecName(_ fourCC: String) -> String {
        switch fourCC {
        case "hvc1", "hev1": "HEVC（H.265）"
        case "avc1", "avc3": "H.264"
        case "ap4h", "ap4x": "Apple ProRes 4444"
        case "apch": "Apple ProRes 422 HQ"
        case "apcn": "Apple ProRes 422"
        case "apcs": "Apple ProRes 422 LT"
        case "apco": "Apple ProRes 422 Proxy"
        case "av01": "AV1"
        case "vp09": "VP9"
        case "mp4v": "MPEG-4"
        case "jpeg": "Motion JPEG"
        default: fourCC.uppercased()
        }
    }

    /// 音频编码的名称
    static func audioCodecName(_ fourCC: String) -> String {
        switch fourCC {
        case "aac ", "aac": "AAC"
        case "alac": "Apple Lossless"
        case "lpcm": "PCM"
        case ".mp3": "MP3"
        case "ac-3": "AC-3"
        case "ec-3": "E-AC-3"
        case "opus": "Opus"
        default: fourCC.uppercased()
        }
    }

    /// ISO 6709 坐标（视频元数据里的写法）：+35.0114+135.7727+048.000/
    static func parseISO6709(_ text: String) -> MediaMetadata.GeoLocation? {
        let pattern = /([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)?/
        guard let m = text.firstMatch(of: pattern),
              let lat = Double(m.output.1), let lon = Double(m.output.2) else { return nil }
        return .init(latitude: lat, longitude: lon, altitude: m.output.3.flatMap { Double($0) })
    }
}

/// 信息面板的一行：左边名称，右边数值
struct InfoRow: Equatable, Identifiable, Sendable {
    let label: String
    let value: String
    /// 数字和时间用等宽字体
    var mono = false
    var id: String { label }
}

/// 拍摄参数的小方块（光圈 / 快门 / ISO / 焦距）
struct InfoTile: Equatable, Identifiable, Sendable {
    let value: String
    let label: String
    var id: String { label }
}

/// 信息面板要显示的全部内容（已格式化）
struct InfoContent: Equatable, Sendable {
    var title: String
    var subtitle: String
    var file: [InfoRow]
    /// 视频组（只有视频有）
    var video: [InfoRow]?
    /// 拍摄组：上面几行、参数方块、下面几行；全空时显示“没有拍摄信息”
    var captureTop: [InfoRow]
    var tiles: [InfoTile]
    var captureBottom: [InfoRow]
    var location: [InfoRow]?
    /// 拷贝坐标按钮拷贝的文字
    var coordinates: String?
    /// 是否读完（没读完时不显示“没有拍摄信息”，避免闪一下）
    var isComplete: Bool

    var hasCapture: Bool { !captureTop.isEmpty || !tiles.isEmpty || !captureBottom.isEmpty }

    /// - Parameter locale: 只在测试里指定（界面语言），默认跟随当前界面语言
    static func make(_ m: MediaMetadata, locale: Locale? = nil) -> InfoContent {
        func L(_ resource: LocalizedStringResource) -> String {
            var r = resource
            if let locale { r.locale = locale }
            return String(localized: r)
        }
        let numberLocale = locale ?? .autoupdatingCurrent
        let isVideo = m.kind == .video

        // 文件
        var file: [InfoRow] = []
        let folder = (m.url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath
        file.append(InfoRow(label: L("文件夹"), value: folder))
        file.append(InfoRow(label: L("大小"), value: Formatting.fileSize(m.fileSize, locale: numberLocale), mono: true))
        if let w = m.pixelWidth, let h = m.pixelHeight, w > 0, h > 0 {
            file.append(InfoRow(label: L("像素尺寸"), value: "\(w) × \(h)", mono: true))
        }
        let format: String
        if isVideo {
            switch m.url.pathExtension.lowercased() {
            case "mov": format = L("QuickTime 影片")
            case "mp4": format = L("MPEG-4 影片")
            default: format = L("\(m.formatName) 影片")
            }
        } else {
            format = [m.formatName, m.colorProfile].compactMap { $0 }.joined(separator: " · ")
        }
        file.append(InfoRow(label: L("格式"), value: format))
        if let d = m.created { file.append(InfoRow(label: L("创建时间"), value: InfoFormat.dateTime(d), mono: true)) }
        if let d = m.modified { file.append(InfoRow(label: L("修改时间"), value: InfoFormat.dateTime(d), mono: true)) }

        // 视频
        var video: [InfoRow]?
        if isVideo, let v = m.video {
            var rows: [InfoRow] = []
            if let d = v.duration { rows.append(InfoRow(label: L("时长"), value: Formatting.duration(d, locale: numberLocale), mono: true)) }
            if let w = m.pixelWidth, let h = m.pixelHeight, w > 0 {
                rows.append(InfoRow(label: L("分辨率"), value: "\(w) × \(h)", mono: true))
            }
            if let c = v.codec { rows.append(InfoRow(label: L("编码"), value: InfoFormat.codecName(c))) }
            if let f = v.frameRate { rows.append(InfoRow(label: L("帧率"), value: InfoFormat.frameRate(f, locale: numberLocale), mono: true)) }
            if let b = v.bitrate { rows.append(InfoRow(label: L("码率"), value: InfoFormat.bitrate(b, locale: numberLocale), mono: true)) }
            if let a = v.audioCodec {
                var parts = [InfoFormat.audioCodecName(a)]
                switch v.audioChannels {
                case 1: parts.append(L("单声道"))
                case 2: parts.append(L("立体声"))
                case let n? where n > 2: parts.append(L("\(n) 声道"))
                default: break
                }
                if let rate = v.audioSampleRate, rate > 0 { parts.append(InfoFormat.sampleRate(rate, locale: numberLocale)) }
                rows.append(InfoRow(label: L("音频"), value: parts.joined(separator: " · ")))
            }
            video = rows.isEmpty ? nil : rows
        }

        // 拍摄
        var top: [InfoRow] = [], tiles: [InfoTile] = [], bottom: [InfoRow] = []
        if let c = m.capture {
            if let d = c.date { top.append(InfoRow(label: L("拍摄时间"), value: d, mono: true)) }
            if let cam = c.camera { top.append(InfoRow(label: L("相机"), value: cam)) }
            if let lens = c.lens { top.append(InfoRow(label: L("镜头"), value: lens)) }
            if let f = c.fNumber { tiles.append(InfoTile(value: InfoFormat.aperture(f), label: L("光圈"))) }
            if let t = c.exposureTime { tiles.append(InfoTile(value: InfoFormat.shutter(t), label: L("快门"))) }
            if let iso = c.iso { tiles.append(InfoTile(value: "\(iso)", label: "ISO")) }
            if let f = c.focalLength { tiles.append(InfoTile(value: InfoFormat.focalLength(f), label: L("焦距"))) }
            if let ev = c.exposureBias { bottom.append(InfoRow(label: L("曝光补偿"), value: InfoFormat.exposureBias(ev), mono: true)) }
            if let fired = c.flashFired { bottom.append(InfoRow(label: L("闪光灯"), value: fired ? L("闪光") : L("未闪光"))) }
            if let manual = c.whiteBalanceManual {
                bottom.append(InfoRow(label: L("白平衡"), value: manual ? L("手动") : L("自动")))
            }
        }

        // 位置
        var location: [InfoRow]?
        var coordinates: String?
        if let g = m.location {
            var rows = [InfoRow(label: L("纬度"), value: InfoFormat.dms(g.latitude, isLatitude: true), mono: true),
                        InfoRow(label: L("经度"), value: InfoFormat.dms(g.longitude, isLatitude: false), mono: true)]
            if let a = g.altitude { rows.append(InfoRow(label: L("海拔"), value: InfoFormat.altitude(a, locale: numberLocale), mono: true)) }
            location = rows
            coordinates = InfoFormat.coordinates(latitude: g.latitude, longitude: g.longitude)
        }

        let subtitle = isVideo ? L("视频 · \(m.formatName)") : L("图片 · \(m.formatName)")
        return InfoContent(title: m.url.lastPathComponent, subtitle: subtitle,
                           file: file, video: video, captureTop: top, tiles: tiles, captureBottom: bottom,
                           location: location, coordinates: coordinates, isComplete: m.isComplete)
    }

    /// “拷贝信息”的文字：文件名，然后每组一个标题、每行“名称：数值”
    func copyText(locale: Locale? = nil) -> String {
        func L(_ resource: LocalizedStringResource) -> String {
            var r = resource
            if let locale { r.locale = locale }
            return String(localized: r)
        }
        func lines(_ rows: [InfoRow]) -> [String] { rows.map { L("\($0.label)：\($0.value)") } }
        var out = [title]
        out += [""] + [L("文件")] + lines(file)
        if let video { out += [""] + [L("视频")] + lines(video) }
        if hasCapture {
            let tileRows = tiles.map { InfoRow(label: $0.label, value: $0.value) }
            out += [""] + [L("拍摄")] + lines(captureTop + tileRows + captureBottom)
        }
        if let location { out += [""] + [L("位置")] + lines(location) }
        return out.joined(separator: "\n")
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
