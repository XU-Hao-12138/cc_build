import SwiftUI

// MARK: - 时光胶囊视图

struct TimeCapsuleView: View {
    @Bindable var viewModel: RitualViewModel
    @State private var selectedTab = 0
    @State private var showAddSheet = false
    @State private var openingCapsuleId: UUID? = nil

    private var pendingCapsules: [TimeCapsule] { viewModel.capsules.filter { !$0.isOpened } }
    private var openedCapsules: [TimeCapsule] { viewModel.capsules.filter { $0.isOpened } }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab 切换
                tabSelector
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // 内容区
                if viewModel.capsules.isEmpty {
                    EmptyStateView(
                        icon: "💌",
                        title: "写下第一封时光信",
                        description: "把现在的心情和期待\n封存起来留给未来的自己吧",
                        buttonTitle: "写一封信",
                        action: { showAddSheet = true }
                    )
                } else {
                    TabView(selection: $selectedTab) {
                        // 未开启
                        pendingCapsuleList
                            .tag(0)

                        // 已开启
                        openedCapsuleList
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: selectedTab)
                }
            }

            // 悬浮添加按钮
            if !viewModel.capsules.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.lavender, Theme.softPink],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .softPinkShadow()
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("时光胶囊")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackToMapButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCapsuleSheet(viewModel: viewModel)
        }
    }

    // MARK: - Tab 选择器

    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "未开启", count: pendingCapsules.count, isSelected: selectedTab == 0) {
                withAnimation { selectedTab = 0 }
            }
            TabButton(title: "已开启", count: openedCapsules.count, isSelected: selectedTab == 1) {
                withAnimation { selectedTab = 1 }
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }

    // MARK: - 未开启列表

    private var pendingCapsuleList: some View {
        ScrollView {
            if pendingCapsules.isEmpty {
                VStack(spacing: 12) {
                    Text("🔓")
                        .font(.system(size: 48))
                        .padding(.top, 60)
                    Text("所有信件都已开启了~")
                        .font(Theme.cute(15))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(pendingCapsules) { capsule in
                        PendingCapsuleCard(capsule: capsule) {
                            openCapsule(capsule)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - 已开启列表

    private var openedCapsuleList: some View {
        ScrollView {
            if openedCapsules.isEmpty {
                VStack(spacing: 12) {
                    Text("📬")
                        .font(.system(size: 48))
                        .padding(.top, 60)
                    Text("还没有开启过信件")
                        .font(Theme.cute(15))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(openedCapsules) { capsule in
                        OpenedCapsuleCard(capsule: capsule)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - 开启胶囊

    private func openCapsule(_ capsule: TimeCapsule) {
        guard capsule.isUnlockable else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            viewModel.openCapsule(id: capsule.id)
        }
        // 切换到已开启 tab
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { selectedTab = 1 }
        }
    }
}

// MARK: - Tab 按钮

struct TabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(Theme.cute(14))
                if count > 0 {
                    Text("\(count)")
                        .font(Theme.cuteCaption(11))
                        .foregroundStyle(isSelected ? Theme.lavender : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Theme.lavender.opacity(0.15) : Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? .white : .clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small - 2))
            .shadow(color: isSelected ? .black.opacity(0.06) : .clear, radius: 4, y: 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - 未开启胶囊卡片

struct PendingCapsuleCard: View {
    let capsule: TimeCapsule
    let onOpen: () -> Void

    @State private var glowing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 顶部：作者 + 写作时间
            HStack {
                HStack(spacing: 6) {
                    Text(capsule.author == 0 ? "🌸" : "💙")
                        .font(.system(size: 16))
                    Text(capsule.author == 0 ? "小粉写的" : "小蓝写的")
                        .font(Theme.cuteCaption(12))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Text(formattedDate(capsule.createdDate))
                    .font(Theme.cuteCaption(11))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // 中间：锁图标 + 倒计时
            HStack(spacing: 12) {
                if capsule.isUnlockable {
                    // 可以开启状态
                    Text("🎉")
                        .font(.system(size: 32))
                        .scaleEffect(glowing ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: glowing)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    if capsule.isUnlockable {
                        Text("可以打开啦！")
                            .font(Theme.cuteTitle(16))
                            .foregroundStyle(.white)
                    } else {
                        Text("还有 \(capsule.daysUntilUnlock) 天可开启")
                            .font(Theme.cute(15))
                            .foregroundStyle(.white)
                    }

                    Text("解锁日期：\(formattedDate(capsule.unlockDate))")
                        .font(Theme.cuteCaption(11))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            // 底部：开启按钮（仅可开启时显示）
            if capsule.isUnlockable {
                Button(action: onOpen) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.open.fill")
                        Text("打开信件")
                    }
                    .font(Theme.cute(14))
                    .foregroundStyle(Theme.lavender)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: capsule.isUnlockable
                    ? [Theme.coral, Theme.warmYellow]
                    : [Theme.lavender.opacity(0.8), Theme.softPink.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        // 蜡封效果（右下角装饰）
        .overlay(alignment: .bottomTrailing) {
            Text("🔮")
                .font(.system(size: 24))
                .offset(x: -12, y: -12)
                .opacity(0.6)
        }
        .softPinkShadow()
        .onAppear {
            if capsule.isUnlockable { glowing = true }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 已开启胶囊卡片

struct OpenedCapsuleCard: View {
    let capsule: TimeCapsule
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 头部信息
            HStack {
                HStack(spacing: 6) {
                    Text(capsule.author == 0 ? "🌸" : "💙")
                        .font(.system(size: 16))
                    Text(capsule.author == 0 ? "小粉写的" : "小蓝写的")
                        .font(Theme.cute(14))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text("📬 已开启")
                    .font(Theme.cuteCaption(11))
                    .foregroundStyle(Theme.mintGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.mintGreen.opacity(0.1))
                    .clipShape(Capsule())
            }

            // 信件内容
            Text(capsule.content)
                .font(Theme.cute(14))
                .foregroundStyle(.primary)
                .lineLimit(expanded ? nil : 3)
                .animation(.easeInOut, value: expanded)

            if capsule.content.count > 80 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        expanded.toggle()
                    }
                } label: {
                    Text(expanded ? "收起" : "查看全文")
                        .font(Theme.cuteCaption(12))
                        .foregroundStyle(Theme.lavender)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // 日期信息
            HStack {
                Label(formattedDate(capsule.createdDate), systemImage: "pencil")
                    .font(Theme.cuteCaption(11))
                    .foregroundStyle(.secondary)
                Spacer()
                Label(formattedDate(capsule.unlockDate), systemImage: "lock.open")
                    .font(Theme.cuteCaption(11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .softPinkShadow()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 添加胶囊 Sheet

struct AddCapsuleSheet: View {
    @Bindable var viewModel: RitualViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var author = 0
    @State private var unlockDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 作者选择
                    VStack(alignment: .leading, spacing: 10) {
                        Text("这封信由谁来写？")
                            .font(Theme.cute(14))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            AuthorButton(label: "🌸 小粉", isSelected: author == 0) { author = 0 }
                            AuthorButton(label: "💙 小蓝", isSelected: author == 1) { author = 1 }
                        }
                    }
                    .padding(.horizontal, 20)

                    // 内容输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("信的内容")
                            .font(Theme.cute(14))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $content)
                            .font(Theme.cute(15))
                            .frame(minHeight: 160)
                            .padding(12)
                            .background(Color.gray.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                            .overlay(
                                Group {
                                    if content.isEmpty {
                                        Text("写下现在的心情、对未来的期待、对彼此的祝福…")
                                            .font(Theme.cute(14))
                                            .foregroundStyle(.secondary.opacity(0.6))
                                            .padding(16)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                    }
                    .padding(.horizontal, 20)

                    // 解锁日期
                    VStack(alignment: .leading, spacing: 8) {
                        Text("什么时候可以打开？")
                            .font(Theme.cute(14))
                            .foregroundStyle(.secondary)

                        DatePicker("", selection: $unlockDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Theme.lavender)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("写一封信")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("封存") {
                        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        let capsule = TimeCapsule(
                            content: content.trimmingCharacters(in: .whitespaces),
                            author: author,
                            unlockDate: unlockDate
                        )
                        viewModel.addCapsule(capsule)
                        dismiss()
                    }
                    .font(Theme.cute(16))
                    .foregroundStyle(content.isEmpty ? .secondary : Theme.lavender)
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - 作者选择按钮

struct AuthorButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.cute(15))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [Theme.lavender, Theme.softPink], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.gray.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
