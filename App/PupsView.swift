import SwiftUI

struct PupsView: View {
    @Environment(PupStore.self) private var store
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.pups.isEmpty {
                    ContentUnavailableView {
                        Label("No pups yet", systemImage: "pawprint")
                    } description: {
                        Text("Add a pup to set up their routine.")
                    } actions: {
                        Button("Add Pup") { showAdd = true }.buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(store.pups) { pup in
                            NavigationLink(value: pup.id) {
                                HStack(spacing: 12) {
                                    PupAvatar(pup: pup, size: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pup.name).font(.headline)
                                        Text([pup.breed, pup.ageText].filter { !$0.isEmpty }.joined(separator: " · "))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { store.deletePup(store.pups[i].id) }
                        }
                    }
                }
            }
            .navigationTitle("My Pups")
            .navigationDestination(for: UUID.self) { PupDetailView(pupID: $0) }
            .toolbar {
                Button("Add Pup", systemImage: "plus") { showAdd = true }
            }
            .sheet(isPresented: $showAdd) { PupEditor() }
        }
    }
}

struct PupDetailView: View {
    @Environment(PupStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let pupID: UUID

    @State private var showEdit = false
    @State private var showAddRoutine = false
    @State private var confirmDelete = false

    var body: some View {
        if let pup = store.pup(pupID) {
            List {
                Section {
                    VStack(spacing: 8) {
                        PupAvatar(pup: pup, size: 88)
                        Text(pup.name).font(.title.bold())
                        Text([pup.breed, pup.ageText].filter { !$0.isEmpty }.joined(separator: " · "))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section("Today") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ActivityKind.allCases) { kind in
                                VStack(spacing: 4) {
                                    KindIcon(kind: kind)
                                    Text("\(store.count(kind, for: pupID))").font(.headline).monospacedDigit()
                                    Text(kind.title).font(.caption2).foregroundStyle(.secondary)
                                }
                                .frame(width: 56)
                            }
                        }
                    }
                }

                Section {
                    let items = store.routine(for: pupID)
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            KindIcon(kind: item.kind, size: 30)
                            Text(item.kind.title)
                            Spacer()
                            Text(item.date(), style: .time).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { store.deleteRoutine(items[i].id) }
                    }
                    Button("Add to Routine", systemImage: "plus.circle.fill") { showAddRoutine = true }
                } header: {
                    Text("Daily routine")
                } footer: {
                    Text("Swipe left on an item to remove it.")
                }

                Section {
                    Button("Remove \(pup.name)", role: .destructive) { confirmDelete = true }
                }
            }
            .navigationTitle(pup.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Edit") { showEdit = true } }
            .sheet(isPresented: $showEdit) { PupEditor(pup: pup) }
            .sheet(isPresented: $showAddRoutine) { RoutineEditor(pupID: pupID) }
            .confirmationDialog("Remove \(pup.name) and all their history?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    store.deletePup(pupID)
                    dismiss()
                }
            }
        }
    }
}

struct RoutineEditor: View {
    @Environment(PupStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let pupID: UUID

    @State private var kind: ActivityKind = .meal
    @State private var time = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Picker("Activity", selection: $kind) {
                    ForEach(ActivityKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.symbol).tag(kind)
                    }
                }
                .pickerStyle(.navigationLink)
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            .navigationTitle("Add to Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addRoutine(RoutineItem(pupID: pupID, kind: kind, minutes: RoutineItem.minutes(from: time)))
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct PupEditor: View {
    @Environment(PupStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let existing: Pup?
    @State private var name: String
    @State private var breed: String
    @State private var emoji: String
    @State private var colorIndex: Int
    @State private var birthday: Date
    @State private var seedRoutine = true

    init(pup: Pup? = nil) {
        existing = pup
        _name = State(initialValue: pup?.name ?? "")
        _breed = State(initialValue: pup?.breed ?? "")
        _emoji = State(initialValue: pup?.emoji ?? "🐶")
        _colorIndex = State(initialValue: pup?.colorIndex ?? Int.random(in: 0..<Theme.palette.count))
        _birthday = State(initialValue: pup?.birthday
            ?? Calendar.current.date(byAdding: .weekOfYear, value: -10, to: .now) ?? .now)
    }

    private var draft: Pup {
        Pup(id: existing?.id ?? UUID(), name: name.trimmingCharacters(in: .whitespaces),
            breed: breed.trimmingCharacters(in: .whitespaces), emoji: emoji,
            colorIndex: colorIndex, birthday: birthday)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PupAvatar(pup: draft, size: 88)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Name", text: $name)
                    TextField("Breed (optional)", text: $breed)
                    DatePicker("Birthday", selection: $birthday, in: ...Date.now, displayedComponents: .date)
                }

                Section("Avatar") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(Theme.emojis, id: \.self) { e in
                            Text(e)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(e == emoji ? Color.accentColor.opacity(0.2) : .clear, in: Circle())
                                .onTapGesture { emoji = e }
                        }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 10) {
                        ForEach(Theme.palette.indices, id: \.self) { i in
                            Circle()
                                .fill(Theme.palette[i])
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if i == colorIndex {
                                        Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorIndex = i }
                        }
                    }
                }

                if existing == nil {
                    Section {
                        Toggle("Start with a puppy schedule", isOn: $seedRoutine)
                    } footer: {
                        Text("Adds typical meals, potty breaks, walks, naps and play. You can edit it later.")
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Pup" : "Edit Pup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if existing == nil {
                            store.addPup(draft, seedRoutine: seedRoutine)
                        } else {
                            store.update(draft)
                        }
                        dismiss()
                    }
                    .disabled(draft.name.isEmpty)
                }
            }
        }
    }
}
