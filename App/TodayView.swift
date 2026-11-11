import SwiftUI

struct TodayView: View {
    @Environment(PupStore.self) private var store
    @State private var selected: UUID?
    @State private var showAdd = false

    private var visiblePups: [Pup] {
        let filtered = store.pups.filter { $0.id == selected }
        return filtered.isEmpty ? store.pups : filtered
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if store.pups.isEmpty {
                        emptyState
                    } else {
                        if store.pups.count > 1 { chips }
                        ForEach(visiblePups) { pup in
                            PupCard(pup: pup)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
            .toolbar {
                Button("Add Pup", systemImage: "plus") { showAdd = true }
            }
            .sheet(isPresented: $showAdd) { PupEditor() }
            .sensoryFeedback(.success, trigger: store.logs.count)
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All pups", emoji: "🐾", color: .accentColor, isOn: selected == nil) { selected = nil }
                ForEach(store.pups) { pup in
                    chip(title: pup.name, emoji: pup.emoji, color: pup.color, isOn: selected == pup.id) {
                        selected = pup.id
                    }
                }
            }
        }
    }

    private func chip(title: String, emoji: String, color: Color, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            HStack(spacing: 6) {
                Text(emoji)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .background(isOn ? color : Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🐶").font(.system(size: 72))
            Text("Welcome to your pack").font(.title2.bold())
            Text("Add your first pup to start tracking meals, potty breaks, walks and more.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                showAdd = true
            } label: {
                Label("Add a Pup", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

private struct PupCard: View {
    @Environment(PupStore.self) private var store
    let pup: Pup

    var body: some View {
        let items = store.routine(for: pup.id)
        let done = items.filter { store.isDone($0) }.count
        let todays = store.logs(for: pup.id)

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                PupAvatar(pup: pup)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pup.name).font(.title3.bold())
                    Text(pup.ageText).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if !items.isEmpty {
                    ProgressRing(
                        progress: Double(done) / Double(items.count),
                        label: "\(done)/\(items.count)",
                        color: pup.color
                    )
                }
            }

            if !items.isEmpty {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        RoutineRow(item: item, tint: pup.color)
                        if item.id != items.last?.id { Divider().padding(.leading, 48) }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick log").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ActivityKind.allCases) { kind in
                            QuickLogButton(kind: kind, count: store.count(kind, for: pup.id)) {
                                withAnimation(.snappy) { store.log(kind, for: pup.id) }
                            }
                        }
                    }
                }
            }

            if !todays.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                    ForEach(todays.prefix(3)) { entry in
                        HStack(spacing: 10) {
                            KindIcon(kind: entry.kind, size: 28)
                            Text(entry.kind.title).font(.subheadline)
                            Spacer()
                            Text(entry.date, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

private struct RoutineRow: View {
    @Environment(PupStore.self) private var store
    let item: RoutineItem
    let tint: Color

    var body: some View {
        let done = store.isDone(item)
        let overdue = !done && item.date() < .now

        Button {
            withAnimation(.snappy) { store.toggle(item) }
        } label: {
            HStack(spacing: 12) {
                KindIcon(kind: item.kind)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.kind.title)
                        .font(.body.weight(.medium))
                        .strikethrough(done)
                        .foregroundStyle(done ? .secondary : .primary)
                    Text(item.date(), style: .time)
                        .font(.caption)
                        .foregroundStyle(overdue ? Color.orange : Color.secondary)
                }
                Spacer()
                if overdue {
                    Text("Due").font(.caption2.weight(.bold)).foregroundStyle(.orange)
                }
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(done ? tint : Color.secondary.opacity(0.4))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct QuickLogButton: View {
    let kind: ActivityKind
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: kind.symbol)
                Text(count > 0 ? "\(kind.title) · \(count)" : kind.title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(kind.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(kind.color.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
