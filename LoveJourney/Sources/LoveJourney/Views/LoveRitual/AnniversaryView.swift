import SwiftUI

// MARK: - 纪念日管理视图

struct AnniversaryView: View {
    @Bindable var viewModel: RitualViewModel
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            if viewModel.anniversaries.isEmpty {
                EmptyStateView(
                    icon: "💕",
                    title: "还没有纪念日哦",
                    description: "记录你们在一起的重要日子吧 ~",
                    buttonTitle: "添加纪念日",
                    action: { showAddSheet = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.anniversaries) { anniversary in
                            AnniversaryCard(
                                anniversary: anniversary,
                                days: viewModel.daysUntilNextAnniversary(anniversary)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }

            // 悬浮添加按钮
            if !viewModel.anniversaries.isEmpty {
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
                                        colors: [Theme.softPink, Theme.coral],
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
        .navigationTitle("纪念日")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackToMapButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAnniversarySheet(viewModel: viewModel)
        }
    }
}

// MARK: - 纪念日卡片

struct AnniversaryCard: View {
    let anniversary: Anniversary
    let days: Int

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 16) {
            // 左侧 emoji
            Text(anniversary.emoji)
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .background(daysColor.opacity(0.15))
                .clipShape(Circle())

            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                Text(anniversary.title)
                    .font(Theme.cute(16))
                    .foregroundStyle(.primary)

                Text(formattedDate)
                    .font(Theme.cuteCaption(13))
                    .foregroundStyle(.secondary)

                if anniversary.isRepeating {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("每年重复")
                            .font(Theme.cuteCaption(11))
                    }
                    .foregroundStyle(Theme.lavender)
                }
            }

            Spacer()

            // 右侧倒计时
            daysCountView
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .softPinkShadow()
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: anniversary.date)
    }

    private var daysColor: Color {
        if days == 0 { return Theme.coral }
        if days > 0 { return Theme.softPink }
        return .gray
    }

    private var daysCountView: some View {
        VStack(spacing: 2) {
            if days == 0 {
                Text("🎉")
                    .font(.system(size: 24))
                Text("今天")
                    .font(Theme.cuteCaption(11))
                    .foregroundStyle(Theme.coral)
            } else if days > 0 {
                Text("\(days)")
                    .font(Theme.cuteTitle(22))
                    .foregroundStyle(Theme.softPink)
                Text("天后")
                    .font(Theme.cuteCaption(11))
                    .foregroundStyle(.secondary)
            } else {
                Text("\(-days)")
                    .font(Theme.cuteTitle(22))
                    .foregroundStyle(.gray)
                Text("天前")
                    .font(Theme.cuteCaption(11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56)
    }
}

// MARK: - 添加纪念日 Sheet

struct AddAnniversarySheet: View {
    @Bindable var viewModel: RitualViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var isRepeating = true
    @State private var selectedEmoji = "💕"

    private let emojiOptions = ["💕", "💍", "🎂", "🌸", "🎉", "🌹", "🍰", "🥂", "💏", "👫", "🌙", "⭐", "🏡", "✈️", "🐾"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Emoji 选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择图标")
                            .font(Theme.cute(14))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(emojiOptions, id: \.self) { emoji in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedEmoji = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 52, height: 52)
                                            .background(selectedEmoji == emoji ? Theme.softPink.opacity(0.2) : Color.gray.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                                    .stroke(selectedEmoji == emoji ? Theme.softPink : .clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // 标题输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("纪念日名称")
                            .font(Theme.cute(14))
                            .foregroundStyle(.secondary)

                        TextField("如：在一起纪念日、你的生日…", text: $title)
                            .font(Theme.cute(15))
                            .padding(14)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                    }
                    .padding(.horizontal, 20)

                    // 日期选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("日期")
                            .font(Theme.cute(14))
                            .foregroundStyle(.secondary)

                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Theme.softPink)
                    }
                    .padding(.horizontal, 20)

                    // 是否每年重复
                    Toggle(isOn: $isRepeating) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundStyle(Theme.lavender)
                            Text("每年提醒")
                                .font(Theme.cute(15))
                        }
                    }
                    .tint(Theme.lavender)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("添加纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let new = Anniversary(
                            title: title.trimmingCharacters(in: .whitespaces),
                            date: date,
                            isRepeating: isRepeating,
                            emoji: selectedEmoji
                        )
                        viewModel.addAnniversary(new)
                        dismiss()
                    }
                    .font(Theme.cute(16))
                    .foregroundStyle(title.isEmpty ? .secondary : Theme.coral)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
