import SwiftUI

// MARK: - 匿名告白墙视图

struct AnonymousNoteView: View {
    @Bindable var viewModel: WhisperViewModel
    @State private var newContent = ""
    @State private var isSubmitting = false
    @State private var appearedIDs: Set<UUID> = []
    @FocusState private var isInputFocused: Bool

    // 每张便利贴随机样式（在视图生命周期内稳定）
    @State private var noteStyles: [UUID: StickyNoteStyle] = [:]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 滚动内容区域
            ScrollView {
                VStack(spacing: 20) {
                    // 顶部标题
                    topHeader

                    // 便利贴墙
                    if viewModel.anonymousNotes.isEmpty {
                        emptyState
                    } else {
                        stickyWall
                    }
                }
                .padding(.bottom, 100) // 为底部输入框留空间
            }

            // 底部固定输入区
            inputBar
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackToMapButton()
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
    }

    // MARK: - 顶部标题

    private var topHeader: some View {
        VStack(spacing: 6) {
            Text("匿名告白墙")
                .font(Theme.cuteTitle(24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.lavender, Theme.softPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("悄悄说出心里话，不问是谁 💕")
                .font(Theme.cute(14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("💕")
                .font(.system(size: 56))
                .padding(.top, 40)

            Text("墙上还没有告白")
                .font(Theme.cuteTitle(18))
                .foregroundStyle(Theme.lavender)

            Text("大胆说出来吧~ 匿名的，不怕的 💕")
                .font(Theme.cute(14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - 便利贴网格

    private var stickyWall: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.anonymousNotes) { note in
                StickyNoteCard(
                    note: note,
                    style: noteStyleFor(note)
                )
                .scaleEffect(appearedIDs.contains(note.id) ? 1 : 0.01)
                .opacity(appearedIDs.contains(note.id) ? 1 : 0)
                .onAppear {
                    if !appearedIDs.contains(note.id) {
                        let id = note.id
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05)) {
                            _ = appearedIDs.insert(id)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 底部输入栏

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("说句悄悄话...", text: $newContent, axis: .vertical)
                .font(Theme.cute(15))
                .lineLimit(1...3)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .strokeBorder(Theme.lavender.opacity(0.3), lineWidth: 1)
                        )
                )
                .focused($isInputFocused)

            Button {
                submitNote()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.lavender, Theme.softPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                        .softPinkShadow()

                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            .scaleEffect(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newContent.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
    }

    // MARK: - 提交逻辑

    private func submitNote() {
        let trimmed = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSubmitting = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        viewModel.addAnonymousNote(content: trimmed)
        newContent = ""
        isInputFocused = false
        isSubmitting = false
    }

    // MARK: - 便利贴样式缓存

    private func noteStyleFor(_ note: AnonymousNote) -> StickyNoteStyle {
        if let style = noteStyles[note.id] {
            return style
        }
        let style = StickyNoteStyle.random(seed: note.id)
        noteStyles[note.id] = style
        return style
    }
}

// MARK: - 便利贴样式

struct StickyNoteStyle {
    let backgroundColor: Color
    let rotation: Double

    static func random(seed: UUID) -> StickyNoteStyle {
        // 用 UUID 哈希做确定性随机，保证同一条目每次渲染样式一致
        let hash = abs(seed.hashValue)
        let colors: [Color] = [
            Theme.softPink.opacity(0.25),
            Theme.lavender.opacity(0.25),
            Theme.warmYellow.opacity(0.3),
            Theme.mintGreen.opacity(0.25),
            Theme.babyBlue.opacity(0.25),
            Color(red: 0.98, green: 0.88, blue: 0.95).opacity(0.5),
        ]
        let colorIndex = hash % colors.count
        let rotationSeed = Double(hash % 21) - 10.0  // -10 到 +10 度
        let rotation = rotationSeed * 0.5            // 实际旋转 -5 到 +5 度
        return StickyNoteStyle(
            backgroundColor: colors[colorIndex],
            rotation: rotation
        )
    }
}

// MARK: - 便利贴卡片

struct StickyNoteCard: View {
    let note: AnonymousNote
    let style: StickyNoteStyle

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 内容文字（手写风格 rounded 字体）
            Text(note.content)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.75))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            // 日期
            Text(note.date.formatted(as: "M月d日"))
                .font(.system(size: 11, weight: .light, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(style.backgroundColor)
                .overlay(
                    // 顶部折角装饰线
                    VStack {
                        Divider()
                            .background(Color.white.opacity(0.4))
                            .padding(.top, 28)
                        Spacer()
                    }
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 2, y: 4)
        )
        .rotationEffect(.degrees(style.rotation))
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
