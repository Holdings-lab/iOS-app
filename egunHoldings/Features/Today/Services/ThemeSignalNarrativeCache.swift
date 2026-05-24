import Foundation

/// 백엔드 내러티브 응답을 메모리 + 디스크에 캐싱한다.
/// LLM 호출은 백엔드가 담당하며, iOS는 완성된 문자열만 받아 저장한다.
///
/// Key 형식 : "{tickerId}:{signalDate}"  예) "QQQ:2026-05-24"
/// 유효 기간 : 작성 당일(자정 기준). 다음 날 앱 재시작 시 자동 만료.
actor ThemeSignalNarrativeCache {
    static let shared = ThemeSignalNarrativeCache()

    private var memory: [String: Entry] = [:]

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("theme_signal_narratives.json")
    }()

    struct Entry: Codable {
        let narrative: String
        let writtenAt: Date
    }

    init() {
        Task { await loadDisk() }
    }

    /// 당일 유효한 캐시 항목 반환. 만료됐으면 nil.
    func get(tickerId: String, signalDate: String) -> String? {
        let key = makeKey(tickerId, signalDate)
        guard let entry = memory[key] else { return nil }
        guard Calendar.current.isDateInToday(entry.writtenAt) else {
            memory.removeValue(forKey: key)
            return nil
        }
        return entry.narrative
    }

    /// 백엔드 응답을 캐시에 저장하고 디스크에 동기화한다.
    func set(narrative: String, tickerId: String, signalDate: String) async {
        let key = makeKey(tickerId, signalDate)
        memory[key] = Entry(narrative: narrative, writtenAt: Date())
        await saveDisk()
    }

    // MARK: - Private

    private func loadDisk() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: Entry].self, from: data)
        else { return }
        // 만료 항목 제거 후 메모리에 적재
        memory = decoded.filter { Calendar.current.isDateInToday($0.value.writtenAt) }
    }

    private func saveDisk() async {
        guard let data = try? JSONEncoder().encode(memory) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func makeKey(_ tickerId: String, _ date: String) -> String {
        "\(tickerId):\(date)"
    }
}
