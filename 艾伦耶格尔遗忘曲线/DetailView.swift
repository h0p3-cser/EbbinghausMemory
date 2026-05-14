import SwiftUI

enum ReviewFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case pending = "待复习"
    case completed = "已完成"

    var id: String { rawValue }
}

struct DetailView: View {
    let item: MemoryItem
    @ObservedObject var viewModel: MainViewModel

    @State private var filter: ReviewFilter = .all
    @State private var draftName: String
    @FocusState private var isNameFocused: Bool

    private let calendar = Calendar.current

    init(item: MemoryItem, viewModel: MainViewModel) {
        self.item = item
        self.viewModel = viewModel
        _draftName = State(initialValue: item.listName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 14)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                if overdueCount > 0 {
                    overdueBanner
                }

                Picker("复习进度", selection: $filter) {
                    ForEach(ReviewFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)

                List(filteredRecords) { record in
                    ReviewRecordRow(
                        item: item,
                        record: record,
                        calendar: calendar,
                        reminderTimeText: formattedTime(
                            hour: viewModel.settings.clampedHour,
                            minute: viewModel.settings.clampedMinute
                        )
                    ) {
                        viewModel.markComplete(itemID: item.id, recordID: record.id)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            .padding(24)
        }
        .onChange(of: item.id) { _ in
            draftName = item.listName
        }
        .onChange(of: item.listName) { newValue in
            if !isNameFocused {
                draftName = newValue
            }
        }
        .onChange(of: isNameFocused) { focused in
            if !focused {
                commitName()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                TextField("列表名称", text: $draftName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 30, weight: .semibold))
                    .focused($isNameFocused)
                    .onSubmit(commitName)

                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
                    .help("编辑名称")

                Spacer()
            }

            HStack(spacing: 16) {
                Label(formattedDate(item.creationDate), systemImage: "calendar")
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(item.completedCount()), total: Double(item.reviewRecords.count))
                    .frame(maxWidth: 220)

                Text("\(item.completedCount()) / \(item.reviewRecords.count)")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private var overdueBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text("有 \(overdueCount) 条逾期复习，请尽快完成")
                .font(.headline)

            Spacer()

            Button {
                viewModel.markAllOverdueComplete(itemID: item.id)
            } label: {
                Label("一键补签", systemImage: "checkmark.circle")
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var overdueCount: Int {
        item.overdueCount(calendar: calendar)
    }

    private var filteredRecords: [ReviewRecord] {
        item.reviewRecords
            .filter { record in
                switch filter {
                case .all:
                    return true
                case .pending:
                    return !record.isCompleted
                case .completed:
                    return record.isCompleted
                }
            }
            .sorted { lhs, rhs in
                let lhsRank = sortRank(lhs)
                let rhsRank = sortRank(rhs)

                if lhsRank == rhsRank {
                    return lhs.targetDate < rhs.targetDate
                }

                return lhsRank < rhsRank
            }
    }

    private func sortRank(_ record: ReviewRecord) -> Int {
        switch record.state(calendar: calendar) {
        case .overdue:
            return 0
        case .today:
            return 1
        case .upcoming:
            return 2
        case .completed:
            return 3
        }
    }

    private func commitName() {
        viewModel.updateListName(itemID: item.id, listName: draftName)
        draftName = viewModel.item(with: item.id)?.listName ?? item.listName
    }
}

private struct ReviewRecordRow: View {
    let item: MemoryItem
    let record: ReviewRecord
    let calendar: Calendar
    let reminderTimeText: String
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("第\(ReviewSchedule.dayOffset(for: record, in: item, calendar: calendar))天：\(formattedDate(record.targetDate))")
                    .font(.headline)

                Text("提醒时间 \(reminderTimeText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusLabel

            if record.isActionable(calendar: calendar) {
                Button {
                    onComplete()
                } label: {
                    Label("标记完成", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(record.isActionable(calendar: calendar) ? Color.accentColor.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusLabel: some View {
        let state = record.state(calendar: calendar)

        return Text(state.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusForeground(for: state))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusBackground(for: state))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func statusForeground(for state: ReviewRecordState) -> Color {
        switch state {
        case .overdue:
            return .orange
        case .today:
            return .green
        case .upcoming:
            return .secondary
        case .completed:
            return .blue
        }
    }

    private func statusBackground(for state: ReviewRecordState) -> Color {
        switch state {
        case .overdue:
            return .orange.opacity(0.13)
        case .today:
            return .green.opacity(0.13)
        case .upcoming:
            return .gray.opacity(0.13)
        case .completed:
            return .blue.opacity(0.13)
        }
    }
}

private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = .current
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
