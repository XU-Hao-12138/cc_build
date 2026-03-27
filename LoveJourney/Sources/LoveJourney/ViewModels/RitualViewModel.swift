import Foundation
import Observation

// MARK: - RitualViewModel

@Observable
final class RitualViewModel {

    // MARK: - 数据属性

    var anniversaries: [Anniversary] = []
    var checkIns: [DailyCheckIn] = []
    var wishes: [WishItem] = []
    var capsules: [TimeCapsule] = []

    // MARK: - UserDefaults 键

    private let anniversariesKey = "ritual_anniversaries"
    private let checkInsKey = "ritual_checkIns"
    private let wishesKey = "ritual_wishes"
    private let capsulesKey = "ritual_capsules"

    // MARK: - 内置每日任务库（至少15个）

    static let taskLibrary: [String] = [
        "互道晚安，说一句暖心的话 🌙",
        "拍一张今日穿搭照片 📸",
        "分享一首你喜欢的歌给对方 🎵",
        "给对方一个温暖的拥抱 🤗",
        "说出三个喜欢对方的地方 💬",
        "一起散步10分钟 🚶‍♀️🚶",
        "给对方做一杯饮料 ☕",
        "互相夸奖对方一次 🌸",
        "给对方发一条表白消息 💌",
        "一起看一段搞笑视频 😂",
        "为对方做一件小小的惊喜 🎁",
        "分享今天最开心的一件事 😊",
        "一起制定下一次约会计划 📅",
        "给对方画一幅简笔画 🎨",
        "告诉对方你今天想念他/她的瞬间 💭",
        "一起回忆一段美好记忆 🌈",
        "互相按摩5分钟 💆",
        "给对方写一张小纸条 📝",
        "一起唱一首歌 🎤",
        "说出你们未来的一个小目标 ✨"
    ]

    // MARK: - 初始化

    init() {
        loadAllData()
        ensureTodayCheckIn()
    }

    // MARK: - 计算属性

    /// 最近纪念日倒计时（天数，负数表示已过）
    func daysUntilNextAnniversary(_ anniversary: Anniversary) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if anniversary.isRepeating {
            // 计算今年的纪念日
            var components = calendar.dateComponents([.month, .day], from: anniversary.date)
            let thisYear = calendar.component(.year, from: today)
            components.year = thisYear
            let thisYearDate = calendar.date(from: components) ?? anniversary.date

            if thisYearDate >= today {
                return calendar.dateComponents([.day], from: today, to: thisYearDate).day ?? 0
            } else {
                // 明年的
                components.year = thisYear + 1
                let nextYearDate = calendar.date(from: components) ?? anniversary.date
                return calendar.dateComponents([.day], from: today, to: nextYearDate).day ?? 0
            }
        } else {
            let targetDate = calendar.startOfDay(for: anniversary.date)
            return calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
        }
    }

    /// 连续打卡天数
    var consecutiveCheckInDays: Int {
        let calendar = Calendar.current
        var count = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let hasCheckIn = checkIns.contains { checkIn in
                let day = calendar.startOfDay(for: checkIn.date)
                return day == checkDate && !checkIn.completedBy.isEmpty
            }
            if hasCheckIn {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return count
    }

    /// 今日打卡记录
    var todayCheckIn: DailyCheckIn? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return checkIns.first { calendar.startOfDay(for: $0.date) == today }
    }

    /// 心愿完成数量
    var completedWishCount: Int {
        wishes.filter { $0.isCompleted }.count
    }

    /// 待解锁胶囊数量
    var pendingCapsuleCount: Int {
        capsules.filter { !$0.isOpened }.count
    }

    // MARK: - 纪念日 CRUD

    func addAnniversary(_ anniversary: Anniversary) {
        anniversaries.append(anniversary)
        anniversaries.sort { $0.date < $1.date }
        saveAnniversaries()
    }

    func deleteAnniversary(at offsets: IndexSet) {
        anniversaries.remove(atOffsets: offsets)
        saveAnniversaries()
    }

    func deleteAnniversary(id: UUID) {
        anniversaries.removeAll { $0.id == id }
        saveAnniversaries()
    }

    // MARK: - 每日打卡

    /// 确保今天有打卡任务
    func ensureTodayCheckIn() {
        if todayCheckIn == nil {
            let randomTask = Self.taskLibrary.randomElement() ?? Self.taskLibrary[0]
            let newCheckIn = DailyCheckIn(task: randomTask)
            checkIns.append(newCheckIn)
            saveCheckIns()
        }
    }

    /// 小粉/小蓝打卡（person: 0=小粉, 1=小蓝）
    func performCheckIn(person: Int) {
        guard var today = todayCheckIn else { return }
        guard !today.completedBy.contains(person) else { return }

        today.completedBy.append(person)

        if let index = checkIns.firstIndex(where: { $0.id == today.id }) {
            checkIns[index] = today
        }
        saveCheckIns()
    }

    /// 最近7天每天是否有打卡（用于日历显示）
    func last7DaysCheckInStatus() -> [(date: Date, completed: Bool)] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let day = calendar.startOfDay(for: date)
            let completed = checkIns.contains { checkIn in
                calendar.startOfDay(for: checkIn.date) == day && !checkIn.completedBy.isEmpty
            }
            return (date: day, completed: completed)
        }
    }

    // MARK: - 心愿 CRUD

    func addWish(_ wish: WishItem) {
        wishes.insert(wish, at: 0)
        saveWishes()
    }

    func toggleWish(id: UUID) {
        guard let index = wishes.firstIndex(where: { $0.id == id }) else { return }
        wishes[index].isCompleted.toggle()
        wishes[index].completedDate = wishes[index].isCompleted ? Date() : nil
        saveWishes()
    }

    func deleteWish(id: UUID) {
        wishes.removeAll { $0.id == id }
        saveWishes()
    }

    // MARK: - 时光胶囊

    func addCapsule(_ capsule: TimeCapsule) {
        capsules.insert(capsule, at: 0)
        saveCapsules()
    }

    func openCapsule(id: UUID) {
        guard let index = capsules.firstIndex(where: { $0.id == id }) else { return }
        guard capsules[index].isUnlockable else { return }
        capsules[index].isOpened = true
        saveCapsules()
    }

    // MARK: - 持久化（UserDefaults）

    private func loadAllData() {
        anniversaries = load([Anniversary].self, forKey: anniversariesKey) ?? []
        checkIns = load([DailyCheckIn].self, forKey: checkInsKey) ?? []
        wishes = load([WishItem].self, forKey: wishesKey) ?? []
        capsules = load([TimeCapsule].self, forKey: capsulesKey) ?? []
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func saveAnniversaries() { save(anniversaries, forKey: anniversariesKey) }
    private func saveCheckIns() { save(checkIns, forKey: checkInsKey) }
    private func saveWishes() { save(wishes, forKey: wishesKey) }
    private func saveCapsules() { save(capsules, forKey: capsulesKey) }
}
