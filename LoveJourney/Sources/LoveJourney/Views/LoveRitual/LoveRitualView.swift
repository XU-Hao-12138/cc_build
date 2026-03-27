import SwiftUI

// MARK: - 爱的仪式主入口 Hub

struct LoveRitualView: View {
    @State private var viewModel = RitualViewModel()
    @State private var animateCards = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - 顶部标题
                titleSection

                // MARK: - 2x2 功能卡片网格
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                    spacing: 16
                ) {
                    // 纪念日
                    NavigationLink(destination: AnniversaryView(viewModel: viewModel)) {
                        RitualHubCard(
                            icon: "💕",
                            title: "纪念日",
                            subtitle: anniversarySubtitle,
                            gradient: LinearGradient(
                                colors: [Theme.softPink, Theme.coral.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            delay: 0.1
                        )
                    }
                    .buttonStyle(.plain)

                    // 每日打卡
                    NavigationLink(destination: DailyCheckInView(viewModel: viewModel)) {
                        RitualHubCard(
                            icon: "✅",
                            title: "每日打卡",
                            subtitle: checkInSubtitle,
                            gradient: LinearGradient(
                                colors: [Theme.mintGreen, Theme.babyBlue.opacity(0.8)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            delay: 0.2
                        )
                    }
                    .buttonStyle(.plain)

                    // 心愿清单
                    NavigationLink(destination: WishListView(viewModel: viewModel)) {
                        RitualHubCard(
                            icon: "🌟",
                            title: "心愿清单",
                            subtitle: wishSubtitle,
                            gradient: LinearGradient(
                                colors: [Theme.warmYellow, Theme.coral.opacity(0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            delay: 0.3
                        )
                    }
                    .buttonStyle(.plain)

                    // 时光胶囊
                    NavigationLink(destination: TimeCapsuleView(viewModel: viewModel)) {
                        RitualHubCard(
                            icon: "💌",
                            title: "时光胶囊",
                            subtitle: capsuleSubtitle,
                            gradient: LinearGradient(
                                colors: [Theme.lavender, Theme.softPink.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            delay: 0.4
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackToMapButton()
            }
        }
    }

    // MARK: - 标题区域

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("爱的仪式")
                .font(Theme.cuteTitle(30))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.coral, Theme.lavender],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Text("用心记录每一个温柔的瞬间 ✨")
                .font(Theme.cute(14))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 副标题计算

    private var anniversarySubtitle: String {
        guard let nearest = viewModel.anniversaries.min(by: {
            abs(viewModel.daysUntilNextAnniversary($0)) < abs(viewModel.daysUntilNextAnniversary($1))
        }) else {
            return "暂无纪念日"
        }
        let days = viewModel.daysUntilNextAnniversary(nearest)
        if days == 0 { return "今天就是 \(nearest.emoji)" }
        if days > 0 { return "还有 \(days) 天 \(nearest.emoji)" }
        return "已过 \(-days) 天"
    }

    private var checkInSubtitle: String {
        let streak = viewModel.consecutiveCheckInDays
        if streak == 0 { return "今日待打卡 🌱" }
        return "连续 \(streak) 天 🔥"
    }

    private var wishSubtitle: String {
        let total = viewModel.wishes.count
        let done = viewModel.completedWishCount
        if total == 0 { return "许下第一个心愿" }
        return "\(done)/\(total) 已实现 🌈"
    }

    private var capsuleSubtitle: String {
        let pending = viewModel.pendingCapsuleCount
        let unlockable = viewModel.capsules.filter { $0.isUnlockable }.count
        if unlockable > 0 { return "\(unlockable) 封待开启 🎉" }
        if pending == 0 { return "写下第一封信" }
        return "\(pending) 封未开启 🔒"
    }
}

// MARK: - 功能卡片子组件

struct RitualHubCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let delay: Double

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(icon)
                .font(.system(size: 36))

            Spacer()

            Text(title)
                .font(Theme.cuteTitle(17))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(Theme.cuteCaption(12))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .frame(height: 140)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .softPinkShadow()
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                appeared = true
            }
        }
    }
}
