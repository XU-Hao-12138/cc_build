import SwiftUI

// MARK: - 每日打卡视图

struct DailyCheckInView: View {
    @Bindable var viewModel: RitualViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - 连续打卡天数
                streakSection

                // MARK: - 今日任务卡片
                todayTaskCard

                // MARK: - 最近7天日历
                weekCalendarSection

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("每日打卡")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackToMapButton()
            }
        }
    }

    // MARK: - 连续打卡天数区域

    private var streakSection: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(viewModel.consecutiveCheckInDays)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.coral, Theme.warmYellow],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                Text("🔥")
                    .font(.system(size: 40))
                    .padding(.bottom, 8)
            }

            Text("连续打卡天数")
                .font(Theme.cute(15))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 今日任务卡片

    private var todayTaskCard: some View {
        VStack(spacing: 0) {
            if let checkIn = viewModel.todayCheckIn {
                VStack(spacing: 20) {
                    // 任务描述
                    VStack(spacing: 8) {
                        Text("今日任务")
                            .font(Theme.cuteCaption(12))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(checkIn.task)
                            .font(Theme.cute(18))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(3)
                    }

                    // 打卡按钮区域
                    HStack(spacing: 16) {
                        // 小粉打卡
                        CheckInButton(
                            name: "小粉",
                            emoji: "🌸",
                            isCompleted: checkIn.completedBy.contains(0)
                        ) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.performCheckIn(person: 0)
                        }

                        // 小蓝打卡
                        CheckInButton(
                            name: "小蓝",
                            emoji: "💙",
                            isCompleted: checkIn.completedBy.contains(1)
                        ) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.performCheckIn(person: 1)
                        }
                    }

                    // 双人完成庆祝
                    if checkIn.completedBy.count == 2 {
                        HStack(spacing: 6) {
                            Text("🎉")
                            Text("今天两人都完成啦！")
                                .font(Theme.cute(14))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.full))
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Theme.mintGreen, Theme.babyBlue],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                .softPinkShadow()
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: checkIn.completedBy.count)
            } else {
                // 兜底（不应出现，ensureTodayCheckIn 会处理）
                Text("加载中…")
                    .font(Theme.cute(14))
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 最近7天日历

    private var weekCalendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近 7 天")
                .font(Theme.cute(15))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            HStack(spacing: 0) {
                ForEach(viewModel.last7DaysCheckInStatus(), id: \.date) { item in
                    VStack(spacing: 6) {
                        Text(weekdayLabel(item.date))
                            .font(Theme.cuteCaption(11))
                            .foregroundStyle(.secondary)

                        Text(dayLabel(item.date))
                            .font(Theme.cute(13))
                            .foregroundStyle(item.completed ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(
                                item.completed
                                    ? AnyShapeStyle(LinearGradient(colors: [Theme.mintGreen, Theme.babyBlue], startPoint: .top, endPoint: .bottom))
                                    : AnyShapeStyle(Color.gray.opacity(0.1))
                            )
                            .clipShape(Circle())
                            .overlay(
                                isToday(item.date)
                                    ? Circle().stroke(Theme.coral, lineWidth: 2)
                                    : nil
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .softPinkShadow()
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 日期工具

    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: date))"
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - 打卡按钮子组件

struct CheckInButton: View {
    let name: String
    let emoji: String
    let isCompleted: Bool
    let action: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button {
            guard !isCompleted else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                bouncing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bouncing = false
            }
            action()
        } label: {
            VStack(spacing: 6) {
                Text(isCompleted ? "✅" : emoji)
                    .font(.system(size: 28))
                    .scaleEffect(bouncing ? 1.3 : 1.0)

                Text(isCompleted ? "已打卡" : "\(name)打卡")
                    .font(Theme.cute(13))
                    .foregroundStyle(isCompleted ? .white : .white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isCompleted
                    ? AnyShapeStyle(.white.opacity(0.3))
                    : AnyShapeStyle(.white.opacity(0.18))
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(.white.opacity(isCompleted ? 0.5 : 0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
    }
}
