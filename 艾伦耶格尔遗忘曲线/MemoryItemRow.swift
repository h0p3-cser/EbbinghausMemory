import SwiftUI

struct MemoryItemRow: View {
    let item: MemoryItem
    var isBatchMode = false
    var isSelected = false

    var body: some View {
        HStack(spacing: 10) {
            if isBatchMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.system(size: 16))
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 9, height: 9)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.listName)
                    .lineLimit(1)
                    .font(.body)

                Text("\(item.completedCount()) / \(item.reviewRecords.count) 已完成")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        if item.hasTodayReviews() {
            return .green
        }

        if item.hasOverdueReviews() {
            return .orange
        }

        return .gray
    }
}
