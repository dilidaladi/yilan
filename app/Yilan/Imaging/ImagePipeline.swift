import Foundation

/// 大图加载：内存缓存 + 合并重复请求 + 取消过期的预加载
actor ImagePipeline {
    static let shared = ImagePipeline()

    /// 解码函数（测试里换成可控的假解码）
    typealias Decode = @Sendable (MediaItem, ImageDecoder.Variant) async throws -> DecodedImage

    struct Key: Hashable, Sendable {
        let url: URL
        let modificationDate: Date
        let variant: ImageDecoder.Variant
    }

    private final class KeyBox: NSObject {
        let key: Key
        init(_ key: Key) { self.key = key }
        override var hash: Int { key.hashValue }
        override func isEqual(_ object: Any?) -> Bool { (object as? KeyBox)?.key == key }
    }

    private let cache = NSCache<KeyBox, DecodedImage>()
    private var inFlight: [Key: Task<DecodedImage, Error>] = [:]
    /// 已知打不开的文件（只记文件本身损坏的；文件不见了、读不了不记，下次还会重试）
    private var failures: [Key: DecodeFailure] = [:]
    private let decode: Decode

    init(decode: @escaping Decode = { try await ImageDecoder.decode($0, variant: $1) }) {
        self.decode = decode
        // 屏幕尺寸的图约 30–70 MB，留出前后各 2 张 + 当前 + 少量历史的空间
        cache.totalCostLimit = 900 * 1024 * 1024
        cache.countLimit = 16
    }

    static func key(_ item: MediaItem, _ variant: ImageDecoder.Variant) -> Key {
        Key(url: item.url, modificationDate: item.modificationDate, variant: variant)
    }

    /// 只查缓存，不触发解码
    func cached(_ item: MediaItem, _ variant: ImageDecoder.Variant) -> DecodedImage? {
        cache.object(forKey: KeyBox(Self.key(item, variant)))
    }

    /// 取图：命中缓存直接返回；已经在解码就等它；否则开始解码。
    /// 共用的解码被别人取消了（例如切换太快时过期的 cancelAll），而调用方自己没被取消，就重新解码一次。
    /// 预加载不重试：它被取消正是 cancelAll 想要的
    func image(_ item: MediaItem, _ variant: ImageDecoder.Variant,
               priority: TaskPriority = .userInitiated, retryIfCancelled: Bool = true) async throws -> DecodedImage {
        do {
            return try await load(item, variant, priority: priority)
        } catch is CancellationError where retryIfCancelled && !Task.isCancelled {
            return try await load(item, variant, priority: priority)
        }
    }

    private func load(_ item: MediaItem, _ variant: ImageDecoder.Variant, priority: TaskPriority) async throws -> DecodedImage {
        let key = Self.key(item, variant)
        if let hit = cache.object(forKey: KeyBox(key)) { return hit }
        if let failure = failures[key] { throw failure }
        let task: Task<DecodedImage, Error>
        if let running = inFlight[key] {
            task = running
        } else {
            let decode = self.decode
            task = Task.detached(priority: priority) { try await decode(item, variant) }
            inFlight[key] = task
        }
        // 等待期间这一项可能已被 cancelAll 移走、又换成了新的解码：只清掉自己那一个
        defer { if inFlight[key] == task { inFlight[key] = nil } }
        do {
            let result = try await task.value
            cache.setObject(result, forKey: KeyBox(key), cost: result.memoryCost)
            return result
        } catch let failure as DecodeFailure {
            if failure.kind.isRemembered { failures[key] = failure }
            throw failure
        }
    }

    /// 后台预加载（不等待结果）
    func preload(_ item: MediaItem, _ variant: ImageDecoder.Variant) {
        let key = Self.key(item, variant)
        guard cache.object(forKey: KeyBox(key)) == nil, failures[key] == nil, inFlight[key] == nil else { return }
        Task(priority: .utility) { _ = try? await self.image(item, variant, priority: .utility, retryIfCancelled: false) }
    }

    /// 取消不在 keep 里的进行中的解码（切换太快时，旧的预加载不再需要）
    func cancelAll(except keep: Set<URL>) {
        for (key, task) in inFlight where !keep.contains(key.url) {
            task.cancel()
            inFlight[key] = nil
        }
    }

    /// 忘掉记住的失败（重新打开文件夹时调用：文件可能已经被修好或换掉）
    func clearFailures() {
        failures.removeAll()
    }

    /// 这些文件在磁盘上变了（文件夹同步）：忘掉记住的失败，下次重新解码。
    /// 缓存按修改时间区分版本，旧版本会自然被挤出去
    func forget(_ urls: Set<URL>) {
        failures = failures.filter { !urls.contains($0.key.url) }
    }

    /// 内存紧张：清空大图缓存（正在显示的那张由界面持有，不受影响）
    func trimMemory() {
        cache.removeAllObjects()
    }

    func removeAll() {
        cache.removeAllObjects()
        failures.removeAll()
    }

    // MARK: - 测试用

    func isInFlight(_ item: MediaItem, _ variant: ImageDecoder.Variant) -> Bool {
        inFlight[Self.key(item, variant)] != nil
    }

    func rememberedFailure(_ item: MediaItem, _ variant: ImageDecoder.Variant) -> DecodeFailure? {
        failures[Self.key(item, variant)]
    }
}
