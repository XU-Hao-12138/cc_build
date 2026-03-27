import Foundation
import Observation

// MARK: - WhisperViewModel

@Observable
final class WhisperViewModel {

    // MARK: - 数据

    var moods: [DailyMood] = []
    var jarNotes: [LoveJarNote] = []
    var anonymousNotes: [AnonymousNote] = []

    // MARK: - UserDefaults 键名

    private let moodsKey = "whisper_moods"
    private let jarNotesKey = "whisper_jar_notes"
    private let anonymousNotesKey = "whisper_anonymous_notes"

    // MARK: - 初始化

    init() {
        loadAll()
    }

    // MARK: - 统计属性

    /// 罐子里的总条数
    var jarNoteCount: Int {
        jarNotes.count
    }

    /// 已开启的条数
    var revealedCount: Int {
        jarNotes.filter(\.isRevealed).count
    }

    /// 未开启的条数
    var unrevealedCount: Int {
        jarNotes.filter { !$0.isRevealed }.count
    }

    /// 匿名告白总数
    var anonymousNoteCount: Int {
        anonymousNotes.count
    }

    // MARK: - 今日心情查询

    /// 查询今天某人是否已打卡
    func todayMood(for player: Int) -> DailyMood? {
        let calendar = Calendar.current
        return moods.first {
            $0.author == player && calendar.isDateInToday($0.date)
        }
    }

    /// 获取某天的心情列表（按日期分组）
    func moods(for date: Date) -> [DailyMood] {
        let calendar = Calendar.current
        return moods.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// 最近 30 天的日期列表
    var recentDates: [Date] {
        let calendar = Calendar.current
        return (0..<30).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: Date())
        }.reversed()
    }

    // MARK: - 心情 CRUD

    /// 添加今日心情
    func addMood(emoji: String, note: String, author: Int) {
        let mood = DailyMood(emoji: emoji, note: note, author: author)
        moods.append(mood)
        saveMoods()
    }

    /// 删除心情记录
    func deleteMood(id: UUID) {
        moods.removeAll { $0.id == id }
        saveMoods()
    }

    // MARK: - 存钱罐操作

    /// 存入一条爱语
    func addJarNote(content: String, author: Int) {
        let note = LoveJarNote(content: content, author: author)
        jarNotes.append(note)
        saveJarNotes()
    }

    /// 随机取出一条未开启的
    func randomUnrevealedNote() -> LoveJarNote? {
        let unrevealed = jarNotes.filter { !$0.isRevealed }
        return unrevealed.randomElement()
    }

    /// 开启某条爱语（标记为已揭示）
    func revealNote(id: UUID) {
        if let index = jarNotes.firstIndex(where: { $0.id == id }) {
            jarNotes[index].isRevealed = true
            saveJarNotes()
        }
    }

    /// 删除爱语
    func deleteJarNote(id: UUID) {
        jarNotes.removeAll { $0.id == id }
        saveJarNotes()
    }

    // MARK: - 匿名告白操作

    /// 添加匿名告白
    func addAnonymousNote(content: String) {
        let note = AnonymousNote(content: content)
        anonymousNotes.insert(note, at: 0) // 新的在最前面
        saveAnonymousNotes()
    }

    /// 删除匿名告白
    func deleteAnonymousNote(id: UUID) {
        anonymousNotes.removeAll { $0.id == id }
        saveAnonymousNotes()
    }

    // MARK: - 持久化：读取

    private func loadAll() {
        moods = load([DailyMood].self, key: moodsKey) ?? []
        jarNotes = load([LoveJarNote].self, key: jarNotesKey) ?? []
        anonymousNotes = load([AnonymousNote].self, key: anonymousNotesKey) ?? []
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - 持久化：保存

    private func saveMoods() {
        save(moods, key: moodsKey)
    }

    private func saveJarNotes() {
        save(jarNotes, key: jarNotesKey)
    }

    private func saveAnonymousNotes() {
        save(anonymousNotes, key: anonymousNotesKey)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
