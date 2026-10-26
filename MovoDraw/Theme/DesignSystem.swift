import SwiftUI

enum MDColor {
    static let skyTop = Color(red: 0.45, green: 0.78, blue: 0.98)
    static let skyBottom = Color(red: 0.92, green: 0.97, blue: 1.0)
    static let grass = Color(red: 0.42, green: 0.78, blue: 0.45)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let sunshine = Color(red: 1.0, green: 0.84, blue: 0.2)
    static let grape = Color(red: 0.55, green: 0.4, blue: 0.95)
    static let mint = Color(red: 0.35, green: 0.85, blue: 0.72)
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.22)
    static let cream = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let canvas = Color.white
}

enum MDLayout {
    /// Fat-finger friendly — usable by a 2-year-old.
    static let bigButton: CGFloat = 72
    static let colorSwatch: CGFloat = 56
    static let corner: CGFloat = 28
    static let brushWidth: CGFloat = 14
}

struct KidPrimaryButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .bold))
                Text(title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MDLayout.bigButton)
            .background(
                RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous)
                    .fill(color)
                    .shadow(color: color.opacity(0.45), radius: 10, y: 6)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct KidIconButton: View {
    let systemImage: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: MDLayout.bigButton, height: MDLayout.bigButton)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
