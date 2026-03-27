import SwiftUI

// MARK: - 心愿清单视图

struct WishListView: View {
    @Bindable var viewModel: RitualViewModel

    @State private var newWishText = ""
    @State private var selectedEmoji = "🌟"
    @State private var showEmojiPicker = false
    @State private var celebratingId: UUID? = nil
    @FocusState private var inputFocused: Bool

    private let emojiOptions = ["🌟", "💫", "🌈", "🎯", "🏖️", "🎪", "🍕", "🎬", "✈️", "🎸", "📚", "🌺", "🏔️", "🎡", "💝"]

    private var pendingWishes: [WishItem] { viewModel.wishes.filter { !$0.isCompleted } }
    private var completedWishes: [WishItem] { viewModel.wishes.filter { $0.isCompleted } }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.wishes.isEmpty {
                        emptyStateSection
                    } else {
                        wishContent
                    }
                    // 底部留出输入框高度
                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }

            // 底部输入框
            inputBar
        }
        .navigationTitle("心愿清单")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackToMapButton()
            }
        }
        // 庆祝动画
        .overlay(celebrationOverlay)
    }

    // MARK: - 空状态

    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Text("🌟")
                .font(.system(size: 64))
                .padding(.top, 80)

            Text("许下第一个心愿吧")
                .font(Theme.cuteTitle(20))
                .foregroundStyle(Theme.lavender)

            Text("把你们想做的事统统记下来\n一起去实现它们！")
                .font(Theme.cute(14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - 心愿列表内容

    private var wishContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 进行中
            if !pendingWishes.isEmpty {
                sectionHeader(title: "进行中 🌱", count: pendingWishes.count)
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    ForEach(pendingWishes) { wish in
                        WishCard(wish: wish, isCompleted: false) {
                            completeWish(wish)
                        } onDelete: {
                            viewModel.deleteWish(id: wish.id)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            // 已完成
            if !completedWishes.isEmpty {
                sectionHeader(title: "已实现 ✨", count: completedWishes.count)
                    .padding(.horizontal, 20)
                    .padding(.top, pendingWishes.isEmpty ? 0 : 8)

                VStack(spacing: 12) {
                    ForEach(completedWishes) { wish in
                        WishCard(wish: wish, isCompleted: true) {
                            // 已完成可以反转
                            viewModel.toggleWish(id: wish.id)
                        } onDelete: {
                            viewModel.deleteWish(id: wish.id)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(Theme.cute(16))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(Theme.cuteCaption(12))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.lavender)
                .clipShape(Capsule())
        }
    }

    // MARK: - 底部输入框

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Emoji 选择器（展开时显示）
            if showEmojiPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                                showEmojiPicker = false
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        selectedEmoji == emoji
                                            ? Theme.softPink.opacity(0.2)
                                            : Color.gray.opacity(0.08)
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 52)
                .background(.white)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 12) {
                // Emoji 按钮
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showEmojiPicker.toggle()
                    }
                } label: {
                    Text(selectedEmoji)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(Theme.softPink.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // 文字输入
                TextField("写下你的心愿…", text: $newWishText)
                    .font(Theme.cute(15))
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit { addWish() }

                // 发送按钮
                Button {
                    addWish()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            newWishText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray.opacity(0.3)
                                : Theme.coral
                        )
                }
                .buttonStyle(.plain)
                .disabled(newWishText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white)
            .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.gray.opacity(0.2)), alignment: .top)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showEmojiPicker)
    }

    // MARK: - 庆祝动画叠加层

    @ViewBuilder
    private var celebrationOverlay: some View {
        if celebratingId != nil {
            ConfettiView()
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    // MARK: - 操作

    private func addWish() {
        let text = newWishText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let wish = WishItem(title: text, emoji: selectedEmoji)
        viewModel.addWish(wish)
        newWishText = ""
        inputFocused = false
        showEmojiPicker = false
    }

    private func completeWish(_ wish: WishItem) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        viewModel.toggleWish(id: wish.id)
        celebratingId = wish.id
        withAnimation(.easeOut(duration: 2.0)) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { celebratingId = nil }
        }
    }
}

// MARK: - 心愿卡片

struct WishCard: View {
    let wish: WishItem
    let isCompleted: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            Text(wish.emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 3) {
                Text(wish.title)
                    .font(Theme.cute(15))
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted, color: .secondary)

                if isCompleted, let date = wish.completedDate {
                    Text("实现于 \(formattedDate(date))")
                        .font(Theme.cuteCaption(11))
                        .foregroundStyle(Theme.mintGreen)
                }
            }

            Spacer()

            // 完成/复原按钮
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isCompleted ? Theme.mintGreen : Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(isCompleted ? Color.gray.opacity(0.05) : .white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .softPinkShadow()
        .opacity(isCompleted ? 0.75 : 1.0)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除心愿", systemImage: "trash")
            }
        }
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 简单彩纸动画

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: CGFloat.random(in: 16...28)))
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(p.rotation))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // 生成粒子
            let screenWidth = UIScreen.main.bounds.width
            particles = (0..<20).map { _ in
                ConfettiParticle(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: -30,
                    emoji: ["🎉", "✨", "💕", "🌟", "🎊", "🌸"].randomElement()!
                )
            }
            // 动画下落
            for i in particles.indices {
                withAnimation(
                    .easeIn(duration: Double.random(in: 1.0...1.8))
                    .delay(Double.random(in: 0...0.5))
                ) {
                    particles[i].y = UIScreen.main.bounds.height + 50
                    particles[i].opacity = 0
                    particles[i].rotation = Double.random(in: -360...360)
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let emoji: String
    var opacity: Double = 1.0
    var rotation: Double = 0
}
