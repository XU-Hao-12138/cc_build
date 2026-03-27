import SwiftUI

// MARK: - 爱的存钱罐视图

struct LoveJarView: View {
    @Bindable var viewModel: WhisperViewModel
    @State private var showAddSheet = false
    @State private var revealedNote: LoveJarNote? = nil
    @State private var showEmptyAlert = false
    @State private var showRevealedList = false
    @State private var jarAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // 顶部标题
                topHeader

                // 罐子插画 + 统计
                jarSection

                // 操作按钮
                actionButtons

                // 已开启列表
                if viewModel.revealedCount > 0 {
                    revealedListSection
                }
            }
            .padding(.bottom, 40)
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
            AddJarNoteSheet { content, author in
                viewModel.addJarNote(content: content, author: author)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    jarAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    jarAnimating = false
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $revealedNote) { note in
            RevealNoteSheet(note: note)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("罐子空了 🫙", isPresented: $showEmptyAlert) {
            Button("去存新的", role: .cancel) { showAddSheet = true }
            Button("知道了") {}
        } message: {
            Text("所有爱语都已经被开启了，快去存一些新的甜蜜话语吧~")
        }
    }

    // MARK: - 顶部标题

    private var topHeader: some View {
        VStack(spacing: 6) {
            Text("爱的存钱罐")
                .font(Theme.cuteTitle(24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.warmYellow, Theme.coral],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("存下每一句爱你 💛")
                .font(Theme.cute(14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - 罐子插画区域

    private var jarSection: some View {
        VStack(spacing: 16) {
            // 玻璃罐子
            GlassJarView(noteCount: viewModel.jarNoteCount)
                .frame(width: 160, height: 200)
                .scaleEffect(jarAnimating ? 1.06 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: jarAnimating)

            // 统计文字
            VStack(spacing: 4) {
                Text("已存 \(viewModel.jarNoteCount) 条爱语")
                    .font(Theme.cuteTitle(16))
                    .foregroundStyle(Theme.warmYellow)

                if viewModel.unrevealedCount > 0 {
                    Text("还有 \(viewModel.unrevealedCount) 条等待开启 ✨")
                        .font(Theme.cuteCaption(13))
                        .foregroundStyle(.secondary)
                } else if viewModel.jarNoteCount > 0 {
                    Text("所有爱语都已开启，再存一些吧~")
                        .font(Theme.cuteCaption(13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        HStack(spacing: 16) {
            CuteButton(
                title: "存一条",
                icon: "💝",
                gradient: LinearGradient(
                    colors: [Theme.softPink, Theme.coral.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ) {
                showAddSheet = true
            }

            CuteButton(
                title: "开罐！",
                icon: "🎁",
                gradient: LinearGradient(
                    colors: [Theme.warmYellow, Theme.coral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                if let note = viewModel.randomUnrevealedNote() {
                    viewModel.revealNote(id: note.id)
                    // 获取更新后的 note（已标记 isRevealed）
                    if let updated = viewModel.jarNotes.first(where: { $0.id == note.id }) {
                        revealedNote = updated
                    }
                } else {
                    showEmptyAlert = true
                }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 已开启列表

    private var revealedListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showRevealedList.toggle()
                }
            } label: {
                HStack {
                    Text("已开启的爱语 (\(viewModel.revealedCount))")
                        .font(Theme.cuteTitle(15))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showRevealedList ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)

            if showRevealedList {
                VStack(spacing: 10) {
                    ForEach(viewModel.jarNotes.filter(\.isRevealed)) { note in
                        RevealedNoteRow(note: note)
                    }
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - 玻璃罐子视图

struct GlassJarView: View {
    let noteCount: Int

    // 根据数量判断填充级别
    private var fillLevel: CGFloat {
        switch noteCount {
        case 0: return 0
        case 1...5: return 0.25
        case 6...15: return 0.55
        default: return 0.82
        }
    }

    // 随机纸条颜色
    private let noteColors: [Color] = [
        Theme.softPink.opacity(0.8),
        Theme.lavender.opacity(0.8),
        Theme.warmYellow.opacity(0.8),
        Theme.mintGreen.opacity(0.7),
        Theme.babyBlue.opacity(0.7),
        Theme.coral.opacity(0.6)
    ]

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let jarLeft: CGFloat = w * 0.1
            let jarRight: CGFloat = w * 0.9
            let jarTop: CGFloat = h * 0.15
            let jarBottom: CGFloat = h * 0.95
            let jarWidth = jarRight - jarLeft
            let jarHeight = jarBottom - jarTop

            // 罐身路径（梯形+圆底）
            var bodyPath = Path()
            let bodyLeft = jarLeft + jarWidth * 0.05
            let bodyRight = jarRight - jarWidth * 0.05
            let neckLeft = jarLeft + jarWidth * 0.1
            let neckRight = jarRight - jarWidth * 0.1
            let neckBottom = jarTop + jarHeight * 0.12

            bodyPath.move(to: CGPoint(x: neckLeft, y: neckBottom))
            bodyPath.addLine(to: CGPoint(x: bodyLeft, y: jarBottom - 12))
            bodyPath.addQuadCurve(
                to: CGPoint(x: bodyRight, y: jarBottom - 12),
                control: CGPoint(x: w * 0.5, y: jarBottom + 8)
            )
            bodyPath.addLine(to: CGPoint(x: neckRight, y: neckBottom))
            bodyPath.closeSubpath()

            // 填充颜色（玻璃效果）
            context.fill(bodyPath, with: .color(Color.white.opacity(0.35)))

            // 纸条填充（根据 fillLevel）
            if fillLevel > 0 {
                let fillHeight = (jarHeight - jarHeight * 0.15) * fillLevel
                let fillTop = jarBottom - 12 - fillHeight
                var fillPath = Path()
                fillPath.move(to: CGPoint(x: bodyLeft + 4, y: fillTop))
                fillPath.addLine(to: CGPoint(x: bodyRight - 4, y: fillTop))
                fillPath.addLine(to: CGPoint(x: bodyRight - 4, y: jarBottom - 14))
                fillPath.addQuadCurve(
                    to: CGPoint(x: bodyLeft + 4, y: jarBottom - 14),
                    control: CGPoint(x: w * 0.5, y: jarBottom + 4)
                )
                fillPath.closeSubpath()

                // 渐变填充模拟堆叠纸条
                context.fill(fillPath, with: .linearGradient(
                    Gradient(colors: [
                        Theme.warmYellow.opacity(0.5),
                        Theme.softPink.opacity(0.6),
                        Theme.lavender.opacity(0.5)
                    ]),
                    startPoint: CGPoint(x: w * 0.5, y: fillTop),
                    endPoint: CGPoint(x: w * 0.5, y: jarBottom)
                ))

                // 模拟纸条线条
                let stripeCount = max(2, Int(fillHeight / 16))
                for i in 0..<stripeCount {
                    let y = fillTop + CGFloat(i) * (fillHeight / CGFloat(stripeCount))
                    let xOffset = CGFloat(i % 2 == 0 ? 8 : 12)
                    var stripe = Path()
                    stripe.move(to: CGPoint(x: bodyLeft + xOffset, y: y + 4))
                    stripe.addLine(to: CGPoint(x: bodyRight - xOffset, y: y + 4))
                    context.stroke(stripe, with: .color(.white.opacity(0.5)), lineWidth: 1)
                }
            }

            // 罐身描边（玻璃感）
            context.stroke(bodyPath, with: .linearGradient(
                Gradient(colors: [Color.white.opacity(0.8), Theme.warmYellow.opacity(0.4)]),
                startPoint: CGPoint(x: jarLeft, y: jarTop),
                endPoint: CGPoint(x: jarRight, y: jarBottom)
            ), lineWidth: 2)

            // 瓶颈
            var neckPath = Path()
            neckPath.move(to: CGPoint(x: neckLeft, y: jarTop + 2))
            neckPath.addLine(to: CGPoint(x: neckLeft, y: neckBottom))
            neckPath.addLine(to: CGPoint(x: neckRight, y: neckBottom))
            neckPath.addLine(to: CGPoint(x: neckRight, y: jarTop + 2))
            neckPath.closeSubpath()
            context.fill(neckPath, with: .color(Color.white.opacity(0.3)))
            context.stroke(neckPath, with: .color(Theme.warmYellow.opacity(0.4)), lineWidth: 1.5)

            // 瓶盖
            var capPath = Path()
            let capLeft = neckLeft - jarWidth * 0.04
            let capRight = neckRight + jarWidth * 0.04
            capPath.addRoundedRect(
                in: CGRect(x: capLeft, y: jarTop - 16, width: capRight - capLeft, height: 18),
                cornerSize: CGSize(width: 5, height: 5)
            )
            context.fill(capPath, with: .linearGradient(
                Gradient(colors: [Theme.warmYellow, Theme.coral.opacity(0.7)]),
                startPoint: CGPoint(x: w * 0.5, y: jarTop - 16),
                endPoint: CGPoint(x: w * 0.5, y: jarTop + 2)
            ))

            // 高光反射
            var highlightPath = Path()
            highlightPath.move(to: CGPoint(x: bodyLeft + 6, y: neckBottom + 8))
            highlightPath.addCurve(
                to: CGPoint(x: bodyLeft + 8, y: jarBottom - 40),
                control1: CGPoint(x: bodyLeft + 2, y: neckBottom + 40),
                control2: CGPoint(x: bodyLeft + 4, y: jarBottom - 70)
            )
            context.stroke(highlightPath, with: .color(Color.white.opacity(0.5)), lineWidth: 3)
        }
    }
}

// MARK: - 已开启爱语行

private struct RevealedNoteRow: View {
    let note: LoveJarNote

    private var authorColor: Color { note.author == 0 ? Theme.softPink : Theme.babyBlue }
    private var authorName: String { note.author == 0 ? "小粉" : "小蓝" }

    var body: some View {
        HStack(spacing: 12) {
            // 作者颜色条
            RoundedRectangle(cornerRadius: 2)
                .fill(authorColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(Theme.cute(14))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(authorName)
                        .font(Theme.cuteCaption(11))
                        .foregroundStyle(authorColor)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(note.date.formatted(as: "M月d日"))
                        .font(Theme.cuteCaption(11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(.white)
        )
        .softPinkShadow()
    }
}

// MARK: - 存入爱语 Sheet

struct AddJarNoteSheet: View {
    let onSave: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedAuthor = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("存一条爱语")
                .font(Theme.cuteTitle(18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.warmYellow, Theme.coral],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, 20)

            // 作者选择
            HStack(spacing: 0) {
                ForEach([0, 1], id: \.self) { player in
                    let name = player == 0 ? "小粉" : "小蓝"
                    let color = player == 0 ? Theme.softPink : Theme.babyBlue
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAuthor = player
                        }
                    } label: {
                        Text(name)
                            .font(Theme.cute(15))
                            .foregroundStyle(selectedAuthor == player ? .white : color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .fill(selectedAuthor == player ? color : color.opacity(0.1))
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedAuthor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.gray.opacity(0.08))
            )
            .padding(.horizontal, 24)

            // 内容输入
            VStack(alignment: .leading, spacing: 8) {
                Text("夸夸 TA 或者说句甜蜜话吧")
                    .font(Theme.cute(14))
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("比如：你笑起来真的好好看 🌸")
                            .font(Theme.cute(14))
                            .foregroundStyle(Color.gray.opacity(0.4))
                            .padding(.horizontal, 4)
                            .padding(.top, 1)
                    }
                    TextEditor(text: $content)
                        .font(Theme.cute(14))
                        .frame(height: 90)
                        .scrollContentBackground(.hidden)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Theme.warmYellow.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                .strokeBorder(Theme.warmYellow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)

            // 存入按钮
            CuteButton(
                title: "存入罐子",
                icon: "💝",
                gradient: LinearGradient(
                    colors: [Theme.warmYellow, Theme.coral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ) {
                guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                onSave(content.trimmingCharacters(in: .whitespacesAndNewlines), selectedAuthor)
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Theme.cream.ignoresSafeArea())
    }
}

// MARK: - 翻牌展示 Sheet

struct RevealNoteSheet: View {
    let note: LoveJarNote

    @Environment(\.dismiss) private var dismiss
    @State private var isFlipped = false

    private var authorColor: Color { note.author == 0 ? Theme.softPink : Theme.babyBlue }
    private var authorName: String { note.author == 0 ? "小粉" : "小蓝" }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("开罐啦！🎉")
                .font(Theme.cuteTitle(22))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.warmYellow, Theme.coral],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // 翻牌卡片
            ZStack {
                // 卡片正面（爱语内容）
                VStack(spacing: 16) {
                    Text("💌")
                        .font(.system(size: 48))

                    Text(note.content)
                        .font(Theme.cute(18))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 12)

                    Text("来自 \(authorName) · \(note.date.formatted(as: "yyyy年M月d日"))")
                        .font(Theme.cuteCaption(12))
                        .foregroundStyle(authorColor)
                }
                .padding(28)
                .frame(width: 280)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                        .fill(
                            LinearGradient(
                                colors: [authorColor.opacity(0.12), Theme.warmYellow.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                                .strokeBorder(authorColor.opacity(0.3), lineWidth: 1.5)
                        )
                )
                .softPinkShadow()
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                    isFlipped = true
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }

            Spacer()

            CuteButton(
                title: "好开心，收下了 ~",
                gradient: LinearGradient(
                    colors: [authorColor.opacity(0.8), authorColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ) {
                dismiss()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Theme.cream.ignoresSafeArea())
    }
}
