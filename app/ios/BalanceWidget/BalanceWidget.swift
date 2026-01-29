import WidgetKit
import SwiftUI

struct WidgetGroupData: Identifiable {
    let id: String
    let name: String
    let balance: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let netBalance: String
    let owed: String
    let owing: String
    let groups: [WidgetGroupData]
    let singleGroupId: String
    let lastUpdated: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            netBalance: "$0.00",
            owed: "Owed: $0.00",
            owing: "Owing: $0.00",
            groups: [
                WidgetGroupData(id: "1", name: "Travel", balance: "$120.00"),
                WidgetGroupData(id: "2", name: "Roommates", balance: "-$45.00")
            ],
            singleGroupId: "",
            lastUpdated: "Just now"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            netBalance: "$0.00",
            owed: "Owed: $0.00",
            owing: "Owing: $0.00",
            groups: [],
            singleGroupId: "",
            lastUpdated: "Just now"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Suite name should match the one configured in Xcode and Flutter
        let userDefaults = UserDefaults(suiteName: "group.com.trustguard.trustguard")
        let netBalance = userDefaults?.string(forKey: "widget_net_balance") ?? "$0.00"
        let owed = userDefaults?.string(forKey: "widget_owed") ?? "Owed: $0.00"
        let owing = userDefaults?.string(forKey: "widget_owing") ?? "Owing: $0.00"
        let lastUpdated = userDefaults?.string(forKey: "widget_last_updated") ?? ""
        let singleGroupId = userDefaults?.string(forKey: "widget_single_group_id") ?? ""

        var groups: [WidgetGroupData] = []
        for i in 0..<5 {
            if let name = userDefaults?.string(forKey: "widget_group_name_\(i)"), !name.isEmpty {
                let id = userDefaults?.string(forKey: "widget_group_id_\(i)") ?? ""
                let balance = userDefaults?.string(forKey: "widget_group_balance_\(i)") ?? "$0.00"
                groups.append(WidgetGroupData(id: id, name: name, balance: balance))
            }
        }

        let entry = SimpleEntry(
            date: Date(),
            netBalance: netBalance,
            owed: owed,
            owing: owing,
            groups: groups,
            singleGroupId: singleGroupId,
            lastUpdated: lastUpdated
        )
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct BalanceWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header

            if family == .systemSmall {
                smallBody
            } else if family == .systemMedium {
                mediumBody
            } else {
                largeBody
            }

            Spacer(minLength: 0)

            if family != .systemSmall {
                footer
            }
        }
        .padding()
        .background(themeBackground)
        .widgetURL(URL(string: entry.singleGroupId.isEmpty ? "trustguard://groups" : "trustguard://groups/\(entry.singleGroupId)"))
    }

    var themeBackground: some View {
        ZStack {
            Color(UIColor.systemBackground)
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var header: some View {
        HStack {
            Image(systemName: "shield.fill")
                .font(.system(size: 10))
                .foregroundColor(.purple)
            Text("TrustGuard")
                .font(.caption2)
                .bold()
                .foregroundColor(.primary)
            Spacer()
        }
    }

    var smallBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer()
            Text(entry.netBalance)
                .font(.title2)
                .bold()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("NET BALANCE")
                .font(.system(size: 7))
                .bold()
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    var mediumBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Text(entry.netBalance)
                .font(.title)
                .bold()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("Global Net Balance")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            HStack {
                VStack(alignment: .leading) {
                    Text(entry.owed)
                        .font(.system(size: 11))
                        .bold()
                        .foregroundColor(.green)
                    Text("Owed to you")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(entry.owing)
                        .font(.system(size: 11))
                        .bold()
                        .foregroundColor(.red)
                    Text("You owe")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    var largeBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            mediumBody

            Divider()

            Text("GROUP BALANCES")
                .font(.system(size: 9))
                .bold()
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                if entry.groups.isEmpty {
                    Text("No active groups")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else {
                    ForEach(entry.groups.prefix(5)) { group in
                        Link(destination: URL(string: "trustguard://groups/\(group.id)")!) {
                            HStack {
                                Text(group.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Spacer()
                                Text(group.balance)
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(group.balance.contains("-") ? .red : .green)
                            }
                        }
                    }
                }
            }
        }
    }

    var footer: some View {
        HStack {
            Text(entry.lastUpdated)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

@main
struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TrustGuard Balance")
        .description("View your group balances at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
