import SwiftUI
import Observation

@Observable
final class PupStore {
    var pups: [Pup] = []
    var routines: [RoutineItem] = []
    var logs: [LogEntry] = []

    private struct Snapshot: Codable {
        var pups: [Pup]
        var routines: [RoutineItem]
        var logs: [LogEntry]
    }

    @ObservationIgnored private let url = URL.documentsDirectory.appending(path: "pup-data.json")

    init() { load() }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        pups = snap.pups
        routines = snap.routines
        logs = snap.logs
    }

    private func save() {
        let snap = Snapshot(pups: pups, routines: routines, logs: logs)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: Pups

    func pup(_ id: UUID) -> Pup? { pups.first { $0.id == id } }

    func addPup(_ pup: Pup, seedRoutine: Bool) {
        pups.append(pup)
        if seedRoutine {
            let defaults: [(ActivityKind, Int)] = [
                (.pee, 7 * 60), (.meal, 7 * 60 + 30), (.walk, 8 * 60 + 30),
                (.nap, 10 * 60), (.meal, 12 * 60), (.training, 15 * 60),
                (.play, 16 * 60 + 30), (.meal, 18 * 60), (.pee, 21 * 60 + 30)
            ]
            routines += defaults.map { RoutineItem(pupID: pup.id, kind: $0.0, minutes: $0.1) }
        }
        save()
    }

    func update(_ pup: Pup) {
        guard let i = pups.firstIndex(where: { $0.id == pup.id }) else { return }
        pups[i] = pup
        save()
    }

    func deletePup(_ id: UUID) {
        pups.removeAll { $0.id == id }
        routines.removeAll { $0.pupID == id }
        logs.removeAll { $0.pupID == id }
        save()
    }

    // MARK: Routine

    func routine(for pupID: UUID) -> [RoutineItem] {
        routines.filter { $0.pupID == pupID }.sorted { $0.minutes < $1.minutes }
    }

    func addRoutine(_ item: RoutineItem) {
        routines.append(item)
        save()
    }

    func deleteRoutine(_ id: UUID) {
        routines.removeAll { $0.id == id }
        for i in logs.indices where logs[i].routineItemID == id { logs[i].routineItemID = nil }
        save()
    }

    func isDone(_ item: RoutineItem, on day: Date = .now) -> Bool {
        logs.contains { $0.routineItemID == item.id && Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    func toggle(_ item: RoutineItem) {
        if isDone(item) {
            logs.removeAll { $0.routineItemID == item.id && Calendar.current.isDateInToday($0.date) }
        } else {
            logs.append(LogEntry(pupID: item.pupID, kind: item.kind, routineItemID: item.id))
        }
        save()
    }

    // MARK: Logging

    /// Logs an activity now; completes the closest unfinished routine item of the same kind (within 90 min).
    func log(_ kind: ActivityKind, for pupID: UUID) {
        let nowMinutes = RoutineItem.minutes(from: .now)
        let match = routine(for: pupID)
            .filter { $0.kind == kind && !isDone($0) && abs($0.minutes - nowMinutes) <= 90 }
            .min { abs($0.minutes - nowMinutes) < abs($1.minutes - nowMinutes) }
        logs.append(LogEntry(pupID: pupID, kind: kind, routineItemID: match?.id))
        save()
    }

    func deleteLog(_ id: UUID) {
        logs.removeAll { $0.id == id }
        save()
    }

    func logs(for pupID: UUID, on day: Date = .now) -> [LogEntry] {
        logs.filter { $0.pupID == pupID && Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }

    func count(_ kind: ActivityKind, for pupID: UUID, on day: Date = .now) -> Int {
        logs(for: pupID, on: day).filter { $0.kind == kind }.count
    }
}
