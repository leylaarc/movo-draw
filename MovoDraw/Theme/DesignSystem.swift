import SwiftUI
import UIKit

// MARK: - Sky Studio design system
// Soft sky atmosphere + warm paper canvas + crayon accents.
// Sleek for tweens, huge targets for toddlers. One accent job per screen.

enum MDColor {
    /// Atmosphere
    static let skyDeep = Color(red: 0.42, green: 0.72, blue: 0.92)
    static let skySoft = Color(red: 0.78, green: 0.91, blue: 0.98)
    static let mist = Color(red: 0.94, green: 0.97, blue: 1.0)
    static let paper = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let paperEdge = Color(red: 0.93, green: 0.95, blue: 0.97)

    /// Type / chrome
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.22)
    static let inkSoft = Color(red: 0.35, green: 0.42, blue: 0.50)

    /// Accents (crayon box — few, bold)
    static let life = Color(red: 1.0, green: 0.38, blue: 0.42)       // Bring to Life
    static let again = Color(red: 0.22, green: 0.72, blue: 0.68)      // Draw Again
    static let tool = Color(red: 0.45, green: 0.52, blue: 0.72)       // Undo / quiet tools
    static let warn = Color(red: 0.95, green: 0.55, blue: 0.25)       // Clear / caution

    /// Magic wash
    static let magicA = Color(red: 0.55, green: 0.78, blue: 0.98)
    static let magicB = Color(red: 0.72, green: 0.62, blue: 0.95)
    static let magicC = Color(red: 1.0, green: 0.55, blue: 0.55)
}

enum MDType {
    /// Brand hero — Arial Rounded (bundled on iOS); falls back to rounded SF.
    static func brand(_ size: CGFloat) -> Font {
        if UIFont(name: "ArialRoundedMTBold", size: size) != nil {
            return .custom("ArialRoundedMTBold", size: size)
        }
        return .system(size: size, weight: .heavy, design: .rounded)
    }

    static func title(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func label(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

enum MDLayout {
    static let bigButton: CGFloat = 76
    static let colorSwatch: CGFloat = 58
    static let toolButton: CGFloat = 64
    static let corner: CGFloat = 36
    static let brushWidth: CGFloat = 16
    static let screenPad: CGFloat = 22
}

// MARK: - Atmosphere

struct StudioAtmosphere: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MDColor.skyDeep, MDColor.skySoft, MDColor.mist],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                Canvas { context, size in
                    for i in 0..<36 {
                        let x = CGFloat((i * 73) % 100) / 100 * size.width
                        let y = CGFloat((i * 47) % 100) / 100 * size.height
                        let r = CGFloat(2 + (i % 3))
                        let rect = CGRect(x: x, y: y, width: r, height: r)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.18)))
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Brand

struct MovoBrandMark: View {
    var size: CGFloat = 48
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 0 : 2) {
            Text("Movo")
                .font(MDType.brand(size))
                .foregroundStyle(MDColor.ink)
            if !compact {
                Text("Draw")
                    .font(MDType.brand(size * 0.72))
                    .foregroundStyle(MDColor.life)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Movo Draw")
    }
}

// MARK: - Buttons

struct KidPrimaryButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                pressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .bold))
                Text(title)
                    .font(MDType.title(26))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MDLayout.bigButton)
            .background(
                RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous)
                    .fill(color)
            )
            .scaleEffect(pressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct KidToolButton: View {
    let systemImage: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: MDLayout.toolButton, height: MDLayout.toolButton)
                .background(
                    Circle()
                        .fill(MDColor.paper.opacity(0.92))
                )
                .overlay(
                    Circle()
                        .strokeBorder(tint.opacity(0.25), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct CrayonSwatch: View {
    let color: Color
    let selected: Bool
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: MDLayout.colorSwatch, height: MDLayout.colorSwatch)
                if selected {
                    Circle()
                        .strokeBorder(MDColor.paper, lineWidth: 4)
                        .frame(width: MDLayout.colorSwatch - 2, height: MDLayout.colorSwatch - 2)
                    Circle()
                        .strokeBorder(MDColor.ink.opacity(0.35), lineWidth: 2)
                        .frame(width: MDLayout.colorSwatch + 6, height: MDLayout.colorSwatch + 6)
                }
            }
            .scaleEffect(selected ? 1.12 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
    }
}
