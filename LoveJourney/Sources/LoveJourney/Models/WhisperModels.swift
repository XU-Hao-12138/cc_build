import Foundation

// MARK: - 每日心情

struct DailyMood: Identifiable, Codable {
    let id: UUID
    let date: Date
    let emoji: String       // 心情 emoji
    let note: String        // 一句话备注
    let author: Int         // 0=小粉, 1=小蓝

    init(id: UUID = UUID(), date: Date = Date(), emoji: String, note: String, author: Int) {
        self.id = id
        self.date = date
        self.emoji = emoji
        self.note = note
        self.author = author
    }
}

// MARK: - 爱的存钱罐条目

struct LoveJarNote: Identifiable, Codable {
    let id: UUID
    let content: String     // 夸赞/爱语内容
    let author: Int         // 0=小粉, 1=小蓝
    let date: Date
    var isRevealed: Bool    // 是否已被开启

    init(id: UUID = UUID(), content: String, author: Int, date: Date = Date(), isRevealed: Bool = false) {
        self.id = id
        self.content = content
        self.author = author
        self.date = date
        self.isRevealed = isRevealed
    }
}

// MARK: - 匿名告白

struct AnonymousNote: Identifiable, Codable {
    let id: UUID
    let content: String
    let date: Date
    // 不存储 author，保持匿名的乐趣

    init(id: UUID = UUID(), content: String, date: Date = Date()) {
        self.id = id
        self.content = content
        self.date = date
    }
}
