import Foundation

// MARK: - 纪念日模型

struct Anniversary: Identifiable, Codable {
    let id: UUID
    var title: String       // "在一起纪念日"、"生日"等
    var date: Date          // 纪念日日期
    var isRepeating: Bool   // 是否每年重复
    var emoji: String       // 装饰 emoji

    init(id: UUID = UUID(), title: String, date: Date, isRepeating: Bool = true, emoji: String = "💕") {
        self.id = id
        self.title = title
        self.date = date
        self.isRepeating = isRepeating
        self.emoji = emoji
    }
}

// MARK: - 每日打卡模型

struct DailyCheckIn: Identifiable, Codable {
    let id: UUID
    let date: Date
    let task: String            // 打卡任务描述
    var completedBy: [Int]      // 0=小粉, 1=小蓝，可以两人都完成

    init(id: UUID = UUID(), date: Date = Date(), task: String, completedBy: [Int] = []) {
        self.id = id
        self.date = date
        self.task = task
        self.completedBy = completedBy
    }
}

// MARK: - 心愿模型

struct WishItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var completedDate: Date?
    var emoji: String

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, completedDate: Date? = nil, emoji: String = "🌟") {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.emoji = emoji
    }
}

// MARK: - 时光胶囊模型

struct TimeCapsule: Identifiable, Codable {
    let id: UUID
    let content: String     // 信的内容
    let author: Int         // 0=小粉, 1=小蓝
    let createdDate: Date
    let unlockDate: Date    // 解锁日期
    var isOpened: Bool

    init(id: UUID = UUID(), content: String, author: Int, createdDate: Date = Date(), unlockDate: Date, isOpened: Bool = false) {
        self.id = id
        self.content = content
        self.author = author
        self.createdDate = createdDate
        self.unlockDate = unlockDate
        self.isOpened = isOpened
    }

    // 是否已到解锁时间
    var isUnlockable: Bool {
        Date() >= unlockDate && !isOpened
    }

    // 距离解锁还有多少天
    var daysUntilUnlock: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: unlockDate)
        return max(0, components.day ?? 0)
    }
}
