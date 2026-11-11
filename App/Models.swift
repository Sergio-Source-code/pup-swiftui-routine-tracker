import SwiftUI

enum ActivityKind: String, Codable, CaseIterable, Identifiable {
    case meal, water, pee, poop, walk, play, training, nap, meds

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meal: "Meal"
        case .water: "Water"
        case .pee: "Pee"
        case .poop: "Poop"
        case .walk: "Walk"
        case .play: "Play"
        case .training: "Training"
        case .nap: "Nap"
        case .meds: "Meds"
        }
    }

    var symbol: String {
        switch self {
        case .meal: "fork.knife"
        case .water: "waterbottle.fill"
        case .pee: "drop.fill"
        case .poop: "leaf.fill"
        case .walk: "figure.walk"
        case .play: "tennisball.fill"
        case .training: "graduationcap.fill"
        case .nap: "moon.zzz.fill"
        case .meds: "pills.fill"
        }
    }

    var color: Color {
        switch self {
        case .meal: .orange
        case .water: .cyan
        case .pee: .yellow
        case .poop: .brown
        case .walk: .green
        case .play: .pink
        case .training: .purple
        case .nap: .indigo
        case .meds: .red
        }
    }
}

enum Theme {
    static let palette: [Color] = [.orange, .pink, .purple, .blue, .teal, .green, .indigo, .red]
    static let emojis = ["🐶", "🐕", "🐩", "🦮", "🐕‍🦺", "🐾", "🐻", "🦊"]
}

struct Pup: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var breed: String = ""
    var emoji: String = "🐶"
    var colorIndex: Int = 0
    var birthday: Date

    var color: Color { Theme.palette[abs(colorIndex) % Theme.palette.count] }

    var ageText: String {
        let cal = Calendar.current
        let days = max(0, cal.dateComponents([.day], from: birthday, to: .now).day ?? 0)
        let weeks = days / 7
        if days < 14 { return "\(days) days old" }
        if weeks < 16 { return "\(weeks) weeks old" }
        let months = cal.dateComponents([.month], from: birthday, to: .now).month ?? 0
        if months < 24 { return "\(months) months old" }
        return "\(months / 12) years old"
    }
}

struct RoutineItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var pupID: UUID
    var kind: ActivityKind
    var minutes: Int // minutes since midnight

    func date(on day: Date = .now) -> Date {
        let start = Calendar.current.startOfDay(for: day)
        return Calendar.current.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    static func minutes(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

struct LogEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var pupID: UUID
    var kind: ActivityKind
    var date: Date = .now
    var routineItemID: UUID?
}
