import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsGroup("外观") {
                HStack(spacing: 14) {
                    ForEach(CalendarTheme.allCases) { theme in
                        ThemeOptionCard(
                            theme: theme,
                            isSelected: model.settings.calendarTheme == theme
                        ) {
                            model.settings.calendarTheme = theme
                        }
                    }
                }
            }

            settingsGroup("状态栏显示") {
                Toggle("显示图标", isOn: $model.settings.showsIcon)
                Toggle("显示年份", isOn: $model.settings.showsYear)
                Toggle("显示月份", isOn: $model.settings.showsMonth)
                Toggle("显示日期", isOn: $model.settings.showsDay)
                Toggle("显示星期", isOn: $model.settings.showsWeekday)
            }

            settingsGroup("节假日数据") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("订阅地址")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    TextField("订阅地址", text: $model.settings.holidaySourceURL)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Button("同步") {
                        model.syncHolidays()
                    }
                    .buttonStyle(.borderedProminent)

                    Text(syncText)
                        .font(.system(size: 12))
                        .foregroundStyle(syncColor)

                    Spacer()
                }

                if let lastSyncedAt = model.holidayStore.lastSyncedAt {
                    Text("上次同步：\(lastSyncedAt.formatted(date: .numeric, time: .shortened))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .frame(width: 440)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func settingsGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(groupBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
            }
        }
    }

    private var groupBackground: Color {
        colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor).opacity(0.55)
            : Color(nsColor: .textBackgroundColor)
    }

    private var syncText: String {
        switch model.holidayStore.syncState {
        case .idle:
            return "待同步"
        case .syncing:
            return "同步中"
        case .success:
            return "已同步"
        case .failed:
            return "同步失败"
        }
    }

    private var syncColor: Color {
        switch model.holidayStore.syncState {
        case .idle:
            return .secondary
        case .syncing:
            return .orange
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
}

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

                Text(theme.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(isHovering ? 0.18 : 0.08), lineWidth: isSelected ? 2 : 1)
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
        .background(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func previewDay(_ text: String, role: PreviewRole) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .monospaced))
            .foregroundStyle(foreground(for: role))
            .frame(width: 34, height: 28)
            .background(background(for: role))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(border(for: role), lineWidth: borderWidth(for: role))
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var cardBackground: Color {
        if isHovering {
            return Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.05)
        }
        return Color.clear
    }

    private func foreground(for role: PreviewRole) -> Color {
        switch (theme, role) {
        case (_, .holiday):
            return ND.accent
        default:
            return .primary
        }
    }

    private func background(for role: PreviewRole) -> Color {
        switch (theme, role) {
        case (.classic, .selected):
            return Color.primary.opacity(0.16)
        case (.classic, .holiday):
            return ND.accent.opacity(0.17)
        case (.soft, .normal), (.soft, .selected), (.soft, .holiday):
            return Color.clear
        case (.classic, .normal):
            return Color.white.opacity(colorScheme == .dark ? 0.10 : 0.55)
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
            return Color.primary.opacity(0.10)
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
