import SwiftUI

struct HistoryView: View {
    @Environment(PupStore.self) private var store
    @State private var filter: UUID?

    private var entries: [LogEntry] {
        store.logs.filter { filter == nil || $0.pupID == filter }
    }

    private var days: [(day: Date, entries: [LogEntry])] {
        let grouped = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { day in
            (day, grouped[day, default: []].sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No activity yet",
                        systemImage: "pawprint",
                        description: Text("Logged meals, walks and potty breaks will show up here.")
                    )
                } else {
                    List {
                        ForEach(days, id: \.day) { section in
                            Section(section.day.formatted(.dateTime.weekday(.wide).month().day())) {
                                ForEach(section.entries) { entry in
                                    row(entry)
                                }
                                .onDelete { offsets in
                                    for i in offsets { store.deleteLog(section.entries[i].id) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .toolbar {
                if store.pups.count > 1 {
                    Menu {
                        Picker("Pup", selection: $filter) {
                            Text("All pups").tag(UUID?.none)
                            ForEach(store.pups) { pup in
                                Text("\(pup.emoji) \(pup.name)").tag(UUID?.some(pup.id))
                            }
                        }
                    } label: {
                        Image(systemName: filter == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
        }
    }

    private func row(_ entry: LogEntry) -> some View {
        HStack(spacing: 12) {
            KindIcon(kind: entry.kind)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.title).font(.body.weight(.medium))
                if let pup = store.pup(entry.pupID) {
                    Text("\(pup.emoji) \(pup.name)").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(entry.date, style: .time).foregroundStyle(.secondary)
        }
    }
}
