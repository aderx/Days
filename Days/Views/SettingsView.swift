import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
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
