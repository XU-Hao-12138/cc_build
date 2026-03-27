import SwiftUI

// MARK: - 悄悄话主入口

struct WhisperView: View {
    @State private var viewModel = WhisperViewModel()
    @State private var selectedTab: WhisperTab? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部标题区域
                headerSection

                // 功能卡片列表
                VStack(spacing: 14) {
                    // 今日心情
                    WhisperEntryCard(
                        emoji: "😊",
                        title: "今日心情",
                        subtitle: todayMoodSubtitle,
                        gradientColors: [Theme.softPink.opacity(0.8), Theme.lavender]
                    ) {
                        selectedTab = .mood
                    }

                    // 爱的存钱罐
                    WhisperEntryCard(
                        emoji: "🫙",
                        title: "爱的存钱罐",
                        subtitle: "已存 \(viewModel.jarNoteCount) 条爱语",
                        gradientColors: [Theme.warmYellow.opacity(0.9), Theme.coral.opacity(0.7)]
                    ) {
                        selectedTab = .jar
                    }

                    // 匿名告白墙
                    WhisperEntryCard(
                        emoji: "💌",
                        title: "匿名告白墙",
                        subtitle: viewModel.anonymousNoteCount > 0
                            ? "\(viewModel.anonymousNoteCount) 条悄悄话"
                            : "还没有告白，快来表达吧~",
                        gradientColors: [Theme.lavender, Theme.babyBlue.opacity(0.8)]
                    ) {
                        selectedTab = .anonymous
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 16)
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
        .navigationDestination(item: $selectedTab) { tab in
            switch tab {
            case .mood:
                DailyMoodView(viewModel: viewModel)
            case .jar:
                LoveJarView(viewModel: viewModel)
            case .anonymous:
                AnonymousNoteView(viewModel: viewModel)
            }
        }
    }

    // MARK: - 顶部标题

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("悄悄话")
                .font(Theme.cuteTitle(28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.lavender, Theme.softPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("只属于你们的私密小空间 ✨")
                .font(Theme.cute(14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - 今日心情副标题

    private var todayMoodSubtitle: String {
        let pink = viewModel.todayMood(for: 0)
        let blue = viewModel.todayMood(for: 1)
        if let p = pink, let b = blue {
            return "今天：\(p.emoji) \(b.emoji)"
        } else if let p = pink {
            return "小粉：\(p.emoji)  小蓝还没记录"
        } else if let b = blue {
            return "小蓝：\(b.emoji)  小粉还没记录"
        } else {
            return "今天还没记录哦~"
        }
    }
}

// MARK: - 导航 Tab 枚举

enum WhisperTab: String, Hashable, Identifiable {
    case mood
    case jar
    case anonymous

    var id: String { rawValue }
}

// MARK: - 功能入口卡片

struct WhisperEntryCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 左侧 emoji 圆形背景
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .softPinkShadow()

                    Text(emoji)
                        .font(.system(size: 30))
                }

                // 右侧文字
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(Theme.cuteTitle(18))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(Theme.cuteCaption(13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(.white)
            )
            .softPinkShadow()
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
