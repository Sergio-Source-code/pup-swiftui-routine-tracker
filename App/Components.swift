import SwiftUI

struct PupAvatar: View {
    let pup: Pup
    var size: CGFloat = 52

    var body: some View {
        Text(pup.emoji)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(pup.color.opacity(0.2), in: Circle())
            .overlay(Circle().strokeBorder(pup.color.opacity(0.5), lineWidth: 2))
    }
}

struct KindIcon: View {
    let kind: ActivityKind
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: kind.symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(kind.color)
            .frame(width: size, height: size)
            .background(kind.color.opacity(0.15), in: Circle())
    }
}

struct ProgressRing: View {
    let progress: Double
    let label: String
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: progress)
            Text(label)
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .frame(width: 52, height: 52)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
