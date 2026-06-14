import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var launchAtLogin = LoginItemManager.isEnabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                appearanceSection
                generalSection
                statusBarSection
                holidaySection
                performanceSection
            }
            .padding(24)
        }
        .frame(width: 460, height: 560)
        .background(ND.black(colorScheme))
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        settingsGroup("外观 / APPEARANCE") {
            VStack(alignment: .leading, spacing: 16) {
                labeledControl("模式") {
                    NDSegmented(
                        items: AppearanceMode.allCases.map(\.displayName),
                        selectedIndex: AppearanceMode.allCases.firstIndex(of: model.settings.appearanceMode) ?? 0
                    ) { index in
                        model.settings.appearanceMode = AppearanceMode.allCases[index]
                    }
                }

                labeledControl("质感") {
                    VStack(alignment: .leading, spacing: 6) {
                        NDSegmented(
                            items: PanelSkin.allCases.map(\.displayName),
                            selectedIndex: PanelSkin.allCases.firstIndex(of: model.settings.panelSkin) ?? 0
                        ) { index in
                            withAnimation(.easeOut(duration: 0.16)) {
                                model.settings.panelSkin = PanelSkin.allCases[index]
                            }
                        }

                        if !PanelSkin.glassAvailable {
                            Text("玻璃质感需要 macOS 26，当前系统将回退为磨砂")
                                .font(.ndMono(11))
                                .foregroundStyle(ND.textDisabled(colorScheme))
                        }
                    }
                }

                labeledControl("日历主题") {
                    HStack(spacing: 12) {
                        ForEach(CalendarTheme.allCases) { theme in
                            ThemeOptionCard(
                                theme: theme,
                                isSelected: model.settings.calendarTheme == theme
                            ) {
                                withAnimation(.easeOut(duration: 0.16)) {
                                    model.settings.calendarTheme = theme
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var generalSection: some View {
        settingsGroup("通用 / GENERAL") {
            SettingToggleRow(
                title: "开机时启动",
                isOn: Binding(
                    get: { launchAtLogin },
                    set: { launchAtLogin = LoginItemManager.setEnabled($0) }
                )
            )
        }
    }

    private var statusBarSection: some View {
        settingsGroup("状态栏显示 / MENU BAR") {
            VStack(spacing: 0) {
                MenuBarPreview(title: model.menuBarTitle, showsIcon: model.settings.showsIcon)
                    .padding(.bottom, 4)

                SettingToggleRow(title: "图标", isOn: $model.settings.showsIcon)
                rowDivider
                SettingToggleRow(title: "年份", isOn: $model.settings.showsYear)
                rowDivider
                SettingToggleRow(title: "月份", isOn: $model.settings.showsMonth)
                rowDivider
                SettingToggleRow(title: "日期", isOn: $model.settings.showsDay)
                rowDivider
                SettingToggleRow(title: "星期", isOn: $model.settings.showsWeekday)
            }
        }
    }

    private var holidaySection: some View {
        settingsGroup("节假日数据 / HOLIDAYS") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("订阅地址")
                        .ndLabelStyle()
                        .foregroundStyle(ND.textSecondary(colorScheme))

                    NDTextField(text: $model.settings.holidaySourceURL, placeholder: "ICS 订阅地址")
                }

                HStack(spacing: 12) {
                    NDActionButton(
                        title: isSyncing ? "同步中…" : "同步",
                        systemImage: "arrow.triangle.2.circlepath",
                        isBusy: isSyncing
                    ) {
                        model.syncHolidays()
                    }

                    SyncStatusBadge(state: model.holidayStore.syncState)

                    Spacer()
                }

                if let lastSyncedAt = model.holidayStore.lastSyncedAt {
                    Text("上次同步 · \(lastSyncedAt.formatted(date: .numeric, time: .shortened))")
                        .font(.ndMono(11))
                        .foregroundStyle(ND.textDisabled(colorScheme))
                }
            }
        }
    }

    private var performanceSection: some View {
        settingsGroup("性能 / PERFORMANCE") {
            VStack(alignment: .leading, spacing: 12) {
                NDSegmented(
                    items: PanelReleaseDelay.allCases.map(\.displayName),
                    selectedIndex: PanelReleaseDelay.allCases.firstIndex(of: model.settings.panelReleaseDelay) ?? 0
                ) { index in
                    withAnimation(.easeOut(duration: 0.16)) {
                        model.settings.panelReleaseDelay = PanelReleaseDelay.allCases[index]
                    }
                }

                Text(model.settings.panelReleaseDelay.detail)
                    .font(.ndMono(11))
                    .foregroundStyle(ND.textSecondary(colorScheme))
            }
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(ND.divider(colorScheme))
            .frame(height: 1)
    }

    private var isSyncing: Bool {
        model.holidayStore.syncState == .syncing
    }

    private func labeledControl<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .ndLabelStyle()
                .foregroundStyle(ND.textSecondary(colorScheme))
            content()
        }
    }

    // MARK: - Group container

    private func settingsGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .ndLabelStyle()
                .foregroundStyle(ND.textSecondary(colorScheme))

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ND.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ND.border(colorScheme), lineWidth: 1)
            }
        }
    }
}

// MARK: - Menu bar preview

private struct MenuBarPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let showsIcon: Bool

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 5) {
                if showsIcon {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .medium))
                }
                Text(title)
                    .font(.ndMono(12, weight: .medium))
            }
            .foregroundStyle(ND.textPrimary(colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ND.surfaceRaised(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(ND.border(colorScheme), lineWidth: 1)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Toggle row

private struct SettingToggleRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.16)) {
                isOn.toggle()
            }
        } label: {
            HStack {
                Text(title)
                    .font(.ndBody(14))
                    .foregroundStyle(ND.textPrimary(colorScheme))
                Spacer()
                NDSwitch(isOn: isOn)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct NDSwitch: View {
    @Environment(\.colorScheme) private var colorScheme
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? ND.textDisplay(colorScheme) : ND.borderVisible(colorScheme))
            Circle()
                .fill(isOn ? ND.black(colorScheme) : ND.surface(colorScheme))
                .padding(3)
        }
        .frame(width: 42, height: 24)
        .animation(.easeOut(duration: 0.16), value: isOn)
    }
}

// MARK: - Segmented control

private struct NDSegmented: View {
    @Environment(\.colorScheme) private var colorScheme

    let items: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isSelected = index == selectedIndex
                Button {
                    onSelect(index)
                } label: {
                    Text(item)
                        .font(.ndMono(12, weight: .medium))
                        .foregroundStyle(isSelected ? ND.textDisplay(colorScheme) : ND.textSecondary(colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(isSelected ? ND.surfaceRaised(colorScheme) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(isSelected ? ND.borderVisible(colorScheme) : Color.clear, lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(ND.black(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(ND.border(colorScheme), lineWidth: 1)
        }
    }
}

// MARK: - Text field

private struct NDTextField: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    let placeholder: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.ndMono(12))
            .foregroundStyle(ND.textPrimary(colorScheme))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(ND.black(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ND.border(colorScheme), lineWidth: 1)
            }
    }
}

// MARK: - Action button

private struct NDActionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    let title: String
    let systemImage: String
    var isBusy: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .rotationEffect(.degrees(isBusy ? 360 : 0))
                    .animation(isBusy ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isBusy)
                Text(title)
                    .font(.ndMono(12, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(ND.accent.opacity(isHovering ? 0.88 : 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .pointingHandOnHover($isHovering)
    }
}

// MARK: - Sync status

private struct SyncStatusBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let state: HolidayStore.SyncState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.ndMono(11, weight: .medium))
                .foregroundStyle(ND.textSecondary(colorScheme))
        }
    }

    private var label: String {
        switch state {
        case .idle: return "待同步"
        case .syncing: return "同步中"
        case .success: return "已同步"
        case .failed: return "同步失败"
        }
    }

    private var color: Color {
        switch state {
        case .idle: return ND.textDisabled(colorScheme)
        case .syncing: return ND.warning
        case .success: return ND.success
        case .failed: return ND.accent
        }
    }
}

// MARK: - Theme option card

private struct ThemeOptionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    let theme: CalendarTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                preview

                HStack(spacing: 6) {
                    Text(theme.displayName)
                        .font(.ndBody(13, weight: .medium))
                        .foregroundStyle(ND.textPrimary(colorScheme))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ND.accent)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? ND.accent : ND.border(colorScheme),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }

    private var preview: some View {
        HStack(spacing: 6) {
            previewDay("8", role: .normal)
            previewDay("9", role: .holiday)
            previewDay("10", role: .selected)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(ND.black(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func previewDay(_ text: String, role: PreviewRole) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .monospaced))
            .foregroundStyle(foreground(for: role))
            .frame(width: 34, height: 28)
            .background(background(for: role))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(border(for: role), lineWidth: borderWidth(for: role))
            }
    }

    private var cardBackground: Color {
        if isSelected {
            return ND.surfaceRaised(colorScheme)
        }
        return isHovering ? ND.surfaceRaised(colorScheme).opacity(0.6) : Color.clear
    }

    private func foreground(for role: PreviewRole) -> Color {
        switch (theme, role) {
        case (_, .holiday):
            return ND.accent
        default:
            return ND.textPrimary(colorScheme)
        }
    }

    private func background(for role: PreviewRole) -> Color {
        switch (theme, role) {
        case (.classic, .selected):
            return Color.primary.opacity(0.16)
        case (.classic, .holiday):
            return ND.accent.opacity(0.17)
        case (.soft, _):
            return Color.clear
        case (.classic, .normal):
            return ND.dayFill(colorScheme)
        }
    }

    private func border(for role: PreviewRole) -> Color {
        switch (theme, role) {
        case (.classic, .selected):
            return Color.primary.opacity(0.16)
        case (.classic, .holiday):
            return ND.accent.opacity(0.7)
        case (.soft, .selected):
            return Color.primary
        case (.soft, .holiday):
            return ND.accent
        default:
            return ND.border(colorScheme)
        }
    }

    private func borderWidth(for role: PreviewRole) -> CGFloat {
        switch (theme, role) {
        case (.soft, .holiday), (.soft, .selected):
            return 1.5
        default:
            return 1
        }
    }

    private enum PreviewRole {
        case normal
        case holiday
        case selected
    }
}
