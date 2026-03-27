import SwiftUI

struct AdventureMapView: View {
    @StateObject private var viewModel = AdventureMapViewModel()
    @State private var selectedDestination: AppDestination?

    // Landmark positions (proportional: 0...1)
    private let landmarkPositions: [(x: CGFloat, y: CGFloat)] = [
        (0.22, 0.15),  // 0: 邂逅之岛 (左上)
        (0.78, 0.15),  // 1: 时光花园 (右上)
        (0.50, 0.38),  // 2: 誓言水晶 (中央)
        (0.20, 0.60),  // 3: 足迹群岛 (左下)
        (0.80, 0.60),  // 4: 告白灯塔 (右下)
        (0.50, 0.82),  // 5: 游戏乐园 (底部中央)
        (0.50, 0.57),  // 6: 爱的仪式 (中央偏下)
        (0.22, 0.40),  // 7: 悄悄话小屋 (左中)
    ]

    // Path connections: indices into landmarkPositions
    private let pathConnections: [(from: Int, to: Int)] = [
        (0, 2), // 邂逅之岛 -> 誓言水晶
        (1, 2), // 时光花园 -> 誓言水晶
        (2, 3), // 誓言水晶 -> 足迹群岛
        (2, 4), // 誓言水晶 -> 告白灯塔
        (0, 3), // 邂逅之岛 -> 足迹群岛
        (1, 4), // 时光花园 -> 告白灯塔
        (3, 5), // 足迹群岛 -> 游戏乐园
        (4, 5), // 告白灯塔 -> 游戏乐园
        (2, 6), // 誓言水晶 -> 爱的仪式
        (6, 5), // 爱的仪式 -> 游戏乐园
        (0, 7), // 邂逅之岛 -> 悄悄话小屋
        (7, 3), // 悄悄话小屋 -> 足迹群岛
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: - Background gradient sky
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.88, blue: 0.92),   // 淡粉
                        Color(red: 0.88, green: 0.82, blue: 0.98),  // 淡紫
                        Color(red: 0.82, green: 0.9, blue: 1.0),    // 淡蓝
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // MARK: - Grass hills at bottom
                GrassHills()
                    .frame(height: geo.size.height * 0.35)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)

                // MARK: - Floating decorations
                FloatingElementsLayer()
                    .frame(width: geo.size.width, height: geo.size.height * 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)

                // MARK: - Main content
                VStack(spacing: 0) {
                    // Top header area
                    HStack(alignment: .top) {
                        Spacer()
                        CoupleHeader()
                        Spacer()
                    }
                    .overlay(alignment: .topTrailing) {
                        LoveLevelBadge(stats: viewModel.stats)
                            .padding(.trailing, 8)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 12)

                    // MARK: - Map area with landmarks
                    GeometryReader { mapGeo in
                        let mapSize = mapGeo.size

                        ZStack {
                            // Paths between landmarks
                            ForEach(0..<pathConnections.count, id: \.self) { index in
                                let conn = pathConnections[index]
                                let fromPos = CGPoint(
                                    x: landmarkPositions[conn.from].x * mapSize.width,
                                    y: landmarkPositions[conn.from].y * mapSize.height
                                )
                                let toPos = CGPoint(
                                    x: landmarkPositions[conn.to].x * mapSize.width,
                                    y: landmarkPositions[conn.to].y * mapSize.height
                                )
                                let fromActive = countForIndex(conn.from) > 0
                                let toActive = countForIndex(conn.to) > 0

                                MapPathView(
                                    from: fromPos,
                                    to: toPos,
                                    isActive: fromActive && toActive
                                )
                            }

                            // Landmarks
                            // 0: 邂逅之岛 -> 我们的故事
                            Button {
                                selectedDestination = .ourStory
                            } label: {
                                LandmarkNode(
                                    sfIcon: "book.heart.fill",
                                    name: "邂逅之岛",
                                    count: viewModel.stats?.memoryCount ?? 0,
                                    color: Theme.softPink
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[0].x * mapSize.width,
                                y: landmarkPositions[0].y * mapSize.height
                            )

                            // 1: 时光花园 -> 我们的故事
                            Button {
                                selectedDestination = .ourStory
                            } label: {
                                LandmarkNode(
                                    sfIcon: "clock.arrow.circlepath",
                                    name: "时光花园",
                                    count: viewModel.stats?.timelineCount ?? 0,
                                    color: Theme.babyBlue
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[1].x * mapSize.width,
                                y: landmarkPositions[1].y * mapSize.height
                            )

                            // 2: 誓言水晶 (里程碑) — largest
                            Button {
                                selectedDestination = .milestones
                            } label: {
                                LandmarkNode(
                                    sfIcon: "star.fill",
                                    name: "誓言水晶",
                                    count: viewModel.stats?.milestoneCount ?? 0,
                                    color: Theme.warmYellow,
                                    size: 90
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[2].x * mapSize.width,
                                y: landmarkPositions[2].y * mapSize.height
                            )

                            // 3: 足迹群岛 -> 我们的故事（地图标签）
                            Button {
                                selectedDestination = .ourStory
                            } label: {
                                LandmarkNode(
                                    sfIcon: "map.fill",
                                    name: "足迹群岛",
                                    count: viewModel.stats?.footprintCount ?? 0,
                                    color: Theme.mintGreen
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[3].x * mapSize.width,
                                y: landmarkPositions[3].y * mapSize.height
                            )

                            // 4: 告白灯塔 (分享)
                            Button {
                                selectedDestination = .shares
                            } label: {
                                LandmarkNode(
                                    sfIcon: "envelope.heart.fill",
                                    name: "告白灯塔",
                                    count: viewModel.stats?.shareCount ?? 0,
                                    color: Theme.lavender
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[4].x * mapSize.width,
                                y: landmarkPositions[4].y * mapSize.height
                            )

                            // 5: 游戏乐园 (小游戏)
                            Button {
                                selectedDestination = .miniGames
                            } label: {
                                LandmarkNode(
                                    sfIcon: "gamecontroller.fill",
                                    name: "游戏乐园",
                                    count: 5,
                                    color: Theme.coral
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[5].x * mapSize.width,
                                y: landmarkPositions[5].y * mapSize.height
                            )

                            // 6: 爱的仪式
                            Button {
                                selectedDestination = .loveRitual
                            } label: {
                                LandmarkNode(
                                    sfIcon: "heart.text.square.fill",
                                    name: "爱的仪式",
                                    count: 4,
                                    color: Theme.softPink
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[6].x * mapSize.width,
                                y: landmarkPositions[6].y * mapSize.height
                            )

                            // 7: 悄悄话小屋 (Whisper)
                            Button {
                                selectedDestination = .whisper
                            } label: {
                                LandmarkNode(
                                    sfIcon: "bubble.heart.fill",
                                    name: "悄悄话小屋",
                                    count: 3,
                                    color: Theme.lavender
                                )
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: landmarkPositions[7].x * mapSize.width,
                                y: landmarkPositions[7].y * mapSize.height
                            )
                        }
                    }

                    // MARK: - Bottom banner
                    UpcomingBanner(milestones: viewModel.upcomingMilestones)
                        .padding(.bottom, 8)
                }
            }
        }
        .navigationDestination(item: $selectedDestination) { destination in
            switch destination {
            case .memories:
                MemoryListView()
            case .timeline:
                TimelineListView()
            case .milestones:
                MilestoneListView()
            case .footprints:
                FootprintListView()
            case .shares:
                ShareListView()
            case .miniGames:
                MiniGameHubView()
            case .loveRitual:
                LoveRitualView()
            case .ourStory:
                OurStoryView()
            case .whisper:
                WhisperView()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // Helper: get count for landmark index
    private func countForIndex(_ index: Int) -> Int {
        guard let stats = viewModel.stats else { return 0 }
        switch index {
        case 0: return stats.memoryCount
        case 1: return stats.timelineCount
        case 2: return stats.milestoneCount
        case 3: return stats.footprintCount
        case 4: return stats.shareCount
        case 5: return 5 // 小游戏数量
        case 6: return 4 // 爱的仪式功能数量
        case 7: return 3 // 悄悄话小屋功能数量
        default: return 0
        }
    }
}

// MARK: - Grass Hills Background

struct GrassHills: View {
    var body: some View {
        ZStack {
            // Back hill
            GrassHillShape(peakX: 0.6, peakHeight: 0.7)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.9, blue: 0.72),
                            Color(red: 0.65, green: 0.85, blue: 0.65),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(0.4)

            // Front hill
            GrassHillShape(peakX: 0.35, peakHeight: 0.55)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.75, green: 0.92, blue: 0.75),
                            Color(red: 0.68, green: 0.88, blue: 0.68),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(0.35)
        }
    }
}

struct GrassHillShape: Shape {
    let peakX: CGFloat
    let peakHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height),
            control: CGPoint(x: rect.width * peakX, y: rect.height * (1 - peakHeight))
        )
        path.closeSubpath()
        return path
    }
}

enum AppDestination: Hashable, Identifiable {
    case memories
    case timeline
    case milestones
    case footprints
    case shares
    case miniGames
    case loveRitual
    case ourStory   // 我们的故事（合并 memories + timeline + footprints）
    case whisper    // 悄悄话小屋

    var id: Self { self }
}
