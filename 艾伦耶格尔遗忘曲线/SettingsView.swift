import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    private var notificationTime: Binding<Date> {
        Binding {
            dateFromSettings()
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            viewModel.updateNotificationTime(
                hour: components.hour ?? viewModel.settings.clampedHour,
                minute: components.minute ?? viewModel.settings.clampedMinute
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("设置", systemImage: "gearshape")
                    .font(.title2.weight(.semibold))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .help("关闭")
            }

            Form {
                Toggle(
                    "开启本地通知提醒",
                    isOn: Binding(
                        get: { viewModel.settings.notificationsEnabled },
                        set: { viewModel.updateNotificationsEnabled($0) }
                    )
                )

                DatePicker(
                    "通知时间",
                    selection: notificationTime,
                    displayedComponents: [.hourAndMinute]
                )
                .disabled(!viewModel.settings.notificationsEnabled)

                if viewModel.shouldShowNotificationWarning {
                    Label("系统通知权限未开启，将无法接收提醒", systemImage: "bell.slash")
                        .foregroundStyle(.orange)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label("浏览已经完成的艾伦耶格尔任务", systemImage: "archivebox")
                    .font(.headline)

                if viewModel.completedRecords.isEmpty {
                    Text("还没有完成记录")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    List(viewModel.completedRecords) { record in
                        HStack {
                            Text(record.itemName)
                                .font(.body)

                            Spacer()

                            Text(formattedDateTime(record.completionDate))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(minHeight: 180)
                }
            }
        }
        .padding(24)
        .frame(width: 520, height: 520)
    }

    private func dateFromSettings() -> Date {
        Calendar.current.date(
            bySettingHour: viewModel.settings.clampedHour,
            minute: viewModel.settings.clampedMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

private func formattedDateTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = .current
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)
}
