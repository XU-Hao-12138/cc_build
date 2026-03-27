import SwiftUI

// MARK: - 今日心情视图

struct DailyMoodView: View {
    @Bindable var viewModel: WhisperViewModel
    @State private var showAddSheet = false
    @State private var addingForPlayer: Int = 0  // 0=小粉, 1=小蓝

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部日期标题
                topHeader

                // 今日心情双栏
                todaySection

                // 心情日历
                moodCalendar
            }
            .padding(.bottom, 32)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackToMapButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MoodInputSheet(player: addingForPlayer) { emoji, note in
                viewModel.addMood(emoji: emoji, note: note, author: addingForPlayer)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 顶部标题

    private var topHeader: some View {
        VStack(spacing: 6) {
            Text("今日心情")
                .font(Theme.cuteTitle(24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.lavender, Theme.softPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text(Date().formatted(as: "M月d日 EEEE"))
                .font(Theme.cute(14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - 今日心情双栏

    private var todaySection: some View {
        HStack(spacing: 14) {
            // 小粉
            TodayMoodCard(
                playerName: "小粉",
                playerColor: Theme.softPink,
                mood: viewModel.todayMood(for: 0)
            ) {
                addingForPlayer = 0
                showAddSheet = true
            }

            // 小蓝
            TodayMoodCard(
                playerName: "小蓝",
                playerColor: Theme.babyBlue,
                mood: viewModel.todayMood(for: 1)
            ) {
                addingForPlayer = 1
                showAddSheet = true
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 心情日历（最近 30 天）

    private var moodCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近 30 天心情")
                .font(Theme.cuteTitle(16))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.recentDates, id: \.self) { date in
                        MoodCalendarCell(
                            date: date,
                            moods: viewModel.moods(for: date)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - 今日心情卡片（单人）

private struct TodayMoodCard: View {
    let playerName: String
    let playerColor: Color
    let mood: DailyMood?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 玩家标签
                Text(playerName)
                    .font(Theme.cute(13))
                    .foregroundStyle(playerColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(playerColor.opacity(0.12))
                    .clipShape(Capsule())

                if let mood {
                    // 已记录状态
                    Text(mood.emoji)
                        .font(.system(size: 40))

                    Text(mood.note.isEmpty ? "今天心情不错~" : mood.note)
                        .font(Theme.cuteCaption(12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(mood.date.formatted(as: "HH:mm"))
                        .font(Theme.cuteCaption(11))
                        .foregroundStyle(playerColor.opacity(0.7))
                } else {
                    // 未记录状态
                    ZStack {
                        Circle()
                            .strokeBorder(
                                playerColor.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                            )
                            .frame(width: 48, height: 48)
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(playerColor.opacity(0.5))
                    }

                    Text("点击记录")
                        .font(Theme.cuteCaption(12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(mood == nil ? Color.white : playerColor.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .strokeBorder(
                                mood == nil
                                    ? playerColor.opacity(0.2)
                                    : playerColor.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .softPinkShadow()
        }
        .buttonStyle(.plain)
        .disabled(mood != nil) // 已记录则不可再点击
    }
}

// MARK: - 心情日历格子

private struct MoodCalendarCell: View {
    let date: Date
    let moods: [DailyMood]

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var pinkMood: DailyMood? { moods.first { $0.author == 0 } }
    private var blueMood: DailyMood? { moods.first { $0.author == 1 } }

    var body: some View {
        VStack(spacing: 4) {
            // 月/日
            Text(date.formatted(as: "d"))
                .font(Theme.cuteCaption(11))
                .foregroundStyle(isToday ? Theme.lavender : .secondary)
                .fontWeight(isToday ? .bold : .regular)

            // 小粉 emoji
            Text(pinkMood?.emoji ?? "·")
                .font(.system(size: pinkMood != nil ? 18 : 14))
                .opacity(pinkMood != nil ? 1 : 0.3)

            // 小蓝 emoji
            Text(blueMood?.emoji ?? "·")
                .font(.system(size: blueMood != nil ? 18 : 14))
                .opacity(blueMood != nil ? 1 : 0.3)
        }
        .frame(width: 40)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(isToday ? Theme.lavender.opacity(0.12) : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .strokeBorder(
                            isToday ? Theme.lavender.opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .softPinkShadow()
    }
}

// MARK: - 心情录入 Sheet

struct MoodInputSheet: View {
    let player: Int
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedEmoji = "😊"
    @State private var note = ""

    private let emojiOptions = [
        "😊", "🥰", "😍", "🤗", "😄",
        "😌", "😎", "🥺", "😢", "😭",
        "😡", "😤", "😴", "🤔", "😶",
        "😋", "🤩", "😏", "🥳", "💕"
    ]

    private var playerName: String { player == 0 ? "小粉" : "小蓝" }
    private var playerColor: Color { player == 0 ? Theme.softPink : Theme.babyBlue }

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            HStack {
                Text("\(playerName)的今日心情")
                    .font(Theme.cuteTitle(18))
                    .foregroundStyle(playerColor)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // 选中的大 emoji 预览
            Text(selectedEmoji)
                .font(.system(size: 64))
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: selectedEmoji)

            // emoji 选择网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .fill(selectedEmoji == emoji
                                          ? playerColor.opacity(0.2)
                                          : Color.gray.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                            .strokeBorder(
                                                selectedEmoji == emoji
                                                    ? playerColor.opacity(0.5)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .scaleEffect(selectedEmoji == emoji ? 1.08 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectedEmoji)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            // 一句话输入
            VStack(alignment: .leading, spacing: 8) {
                Text("一句话记录今天")
                    .font(Theme.cute(14))
                    .foregroundStyle(.secondary)

                TextField("今天感觉怎么样？（可选）", text: $note)
                    .font(Theme.cute(15))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(playerColor.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .strokeBorder(playerColor.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 24)

            // 保存按钮
            CuteButton(
                title: "记录心情",
                icon: selectedEmoji,
                gradient: LinearGradient(
                    colors: [playerColor.opacity(0.8), playerColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                onSave(selectedEmoji, note)
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Theme.cream.ignoresSafeArea())
    }
}
