import SwiftUI
import WidgetKit

struct TodayReviewEntry: TimelineEntry {
    let date: Date
    let itemNames: [String]
}

struct TodayReviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayReviewEntry {
        TodayReviewEntry(date: Date(), itemNames: ["List 1", "List 2"])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayReviewEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayReviewEntry>) -> Void) {
        let now = Date()
        let currentEntry = entry(for: now)
        let nextRefresh = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now

        completion(Timeline(entries: [currentEntry], policy: .after(nextRefresh)))
    }

    private func entry(for date: Date) -> TodayReviewEntry {
        TodayReviewEntry(
            date: date,
            itemNames: WidgetSharedStore.dueTodayNames(on: date)
        )
    }
}

struct TodayReviewWidgetView: View {
    let entry: TodayReviewEntry

    private var hasTasks: Bool { !entry.itemNames.isEmpty }

    /// Apple-style vibrant green when there are review tasks
    private var accentGreen: Color {
        Color(red: 0.20, green: 0.78, blue: 0.35)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("今日复习", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundStyle(hasTasks ? accentGreen : .primary)

                Spacer()

                Text("\(entry.itemNames.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hasTasks ? accentGreen : .secondary)
            }

            if entry.itemNames.isEmpty {
                Spacer()

                Text("今天暂无艾伦耶格尔任务")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.itemNames.prefix(5), id: \.self) { name in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accentGreen)
                                .frame(width: 6, height: 6)

                            Text(name)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }

                    if entry.itemNames.count > 5 {
                        Text("还有 \(entry.itemNames.count - 5) 个")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct TodayReviewWidget: Widget {
    let kind = "TodayReviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayReviewProvider()) { entry in
            TodayReviewWidgetView(entry: entry)
                .padding()
        }
        .configurationDisplayName("今日艾伦耶格尔")
        .description("显示今天需要复习的艾伦耶格尔记忆项目。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct EbbinghausWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayReviewWidget()
    }
}
