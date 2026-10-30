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
    static let bigButton: CGFloat = 72
    static let colorSwatch: CGFloat = 48
    static let colorSwatchCompact: CGFloat = 40
    static let toolButton: CGFloat = 52
    static let strokeTool: CGFloat = 52
    static let corner: CGFloat = 32
    static let brushWidth: CGFloat = 16
    static let screenPad: CGFloat = 18
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
    var size: CGFloat = MDLayout.colorSwatch
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
                    .frame(width: size, height: size)
                    .overlay(
                        // Edge for light crayons (white / cream) so they read on paper
                        Circle()
                            .strokeBorder(MDColor.ink.opacity(0.12), lineWidth: 1)
                    )
                if selected {
                    Circle()
                        .strokeBorder(MDColor.paper, lineWidth: 4)
                        .frame(width: size - 2, height: size - 2)
                    Circle()
                        .strokeBorder(MDColor.ink.opacity(0.35), lineWidth: 2)
                        .frame(width: size + 6, height: size + 6)
                }
            }
            .scaleEffect(selected ? 1.12 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
    }
}

/// Huge stroke-type control with icon + kid label.
struct StrokeStyleButton: View {
    let style: StrokeStyle
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: style.systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(selected ? Color.white : MDColor.inkSoft)
                    .frame(width: MDLayout.strokeTool, height: MDLayout.strokeTool)
                    .background(
                        Circle()
                            .fill(selected ? MDColor.life : MDColor.paper.opacity(0.92))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                selected ? MDColor.life.opacity(0.4) : MDColor.ink.opacity(0.08),
                                lineWidth: 2
                            )
                    )
                Text(style.label)
                    .font(MDType.label(11))
                    .foregroundStyle(selected ? MDColor.ink : MDColor.inkSoft)
                    .lineLimit(1)
            }
            .scaleEffect(selected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.label)
    }
}

/// Size chip with live tip preview circle.
struct PenSizeChip: View {
    let size: PenSize
    let color: Color
    let opacity: CGFloat
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                action()
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(MDColor.paper)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selected ? MDColor.life : MDColor.ink.opacity(0.1),
                                    lineWidth: selected ? 3 : 2
                                )
                        )
                    Circle()
                        .fill(color.opacity(opacity))
                        .frame(
                            width: min(size.width * 0.85, 36),
                            height: min(size.width * 0.85, 36)
                        )
                }
                Text(size.label)
                    .font(MDType.label(12))
                    .foregroundStyle(selected ? MDColor.ink : MDColor.inkSoft)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(size.label)
    }
}

struct OpacityChip: View {
    let preset: OpacityPreset
    let color: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                action()
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MDColor.paper)
                        .frame(width: 64, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    selected ? MDColor.life : MDColor.ink.opacity(0.1),
                                    lineWidth: selected ? 3 : 2
                                )
                        )
                    Capsule()
                        .fill(color.opacity(preset.value))
                        .frame(width: 36, height: 14)
                }
                Text(preset.label)
                    .font(MDType.label(12))
                    .foregroundStyle(selected ? MDColor.ink : MDColor.inkSoft)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.label)
    }
}

/// Compact tip preview — shows current color, size, and opacity together.
struct TipPreview: View {
    let color: Color
    let size: PenSize
    let opacity: CGFloat
    let style: StrokeStyle

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MDColor.paper.opacity(0.95))
                .frame(width: 56, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(MDColor.ink.opacity(0.08), lineWidth: 2)
                )
            if style == .eraser {
                Image(systemName: "eraser")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MDColor.inkSoft)
            } else {
                Circle()
                    .fill(color.opacity(opacity))
                    .frame(
                        width: min(size.width * 0.75, 30),
                        height: min(size.width * 0.75, 30)
                    )
            }
        }
        .accessibilityLabel("Tip preview")
    }
}

/// Opens the drawing tools menu (color, type, size, soft).
struct ToolsMenuButton: View {
    let color: Color
    let style: StrokeStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .strokeBorder(MDColor.ink.opacity(0.12), lineWidth: 1)
                        )
                    if style == .eraser {
                        Image(systemName: "eraser")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MDColor.inkSoft)
                    }
                }
                Text("Tools")
                    .font(MDType.body(17))
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(MDColor.ink)
            .padding(.horizontal, 16)
            .frame(height: MDLayout.toolButton)
            .background(
                Capsule()
                    .fill(MDColor.paper.opacity(0.95))
            )
            .overlay(
                Capsule()
                    .strokeBorder(MDColor.ink.opacity(0.1), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Drawing tools")
    }
}

struct MoreColorsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(MDColor.paper.opacity(0.95))
                        .frame(width: MDLayout.colorSwatch, height: MDLayout.colorSwatch)
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(MDColor.inkSoft)
                }
                .overlay(
                    Circle()
                        .strokeBorder(MDColor.ink.opacity(0.12), lineWidth: 2)
                        .frame(width: MDLayout.colorSwatch, height: MDLayout.colorSwatch)
                )
                Text("Colors")
                    .font(MDType.label(11))
                    .foregroundStyle(MDColor.inkSoft)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More colors")
    }
}

/// Opens the Mix sheet — always visible, not a hidden ColorPicker overlay.
struct MixColorButton: View {
    let current: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(red: 1, green: 0.2, blue: 0.3),
                                    Color(red: 1, green: 0.7, blue: 0.1),
                                    Color(red: 0.25, green: 0.85, blue: 0.35),
                                    Color(red: 0.2, green: 0.55, blue: 1),
                                    Color(red: 0.65, green: 0.3, blue: 0.95),
                                    Color(red: 1, green: 0.2, blue: 0.3)
                                ],
                                center: .center
                            )
                        )
                        .frame(width: MDLayout.colorSwatch, height: MDLayout.colorSwatch)
                    Circle()
                        .fill(current)
                        .frame(width: MDLayout.colorSwatch - 16, height: MDLayout.colorSwatch - 16)
                        .overlay(
                            Circle()
                                .strokeBorder(MDColor.paper, lineWidth: 3)
                        )
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MDColor.ink.opacity(0.55))
                        .offset(x: 16, y: 16)
                }
                Text("Mix")
                    .font(MDType.label(11))
                    .foregroundStyle(MDColor.inkSoft)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mix your own color")
    }
}

/// Tiny section label for tools sheets — quiet, not chrome-y.
struct TraySectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(MDType.label(13))
            .foregroundStyle(MDColor.inkSoft)
            .textCase(.none)
    }
}

/// Named crayon in the More sheet — swatch + readable name (single button).
struct NamedCrayonSwatch: View {
    let crayon: CrayonColor
    let selected: Bool
    let action: () -> Void

    private let size: CGFloat = 58

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                action()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(crayon.color))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .strokeBorder(MDColor.ink.opacity(0.12), lineWidth: 1)
                        )
                    if selected {
                        Circle()
                            .strokeBorder(MDColor.paper, lineWidth: 4)
                            .frame(width: size - 2, height: size - 2)
                        Circle()
                            .strokeBorder(MDColor.ink.opacity(0.35), lineWidth: 2)
                            .frame(width: size + 6, height: size + 6)
                    }
                }
                .scaleEffect(selected ? 1.08 : 1)
                Text(crayon.name)
                    .font(MDType.label(12))
                    .foregroundStyle(selected ? MDColor.ink : MDColor.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(crayon.name)
    }
}

/// Big, fully visible system color picker for the Mix sheet.
struct MixYourOwnColorCard: View {
    @Binding var color: Color
    var onPicked: (Color) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mix your own")
                .font(MDType.title(22))
                .foregroundStyle(MDColor.ink)
            Text("Pick any color")
                .font(MDType.label(15))
                .foregroundStyle(MDColor.inkSoft)

            HStack(spacing: 16) {
                Circle()
                    .fill(color)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .strokeBorder(MDColor.ink.opacity(0.15), lineWidth: 2)
                    )

                ColorPicker("Color", selection: $color, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.35)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: color) { _, newValue in
                        onPicked(newValue)
                    }
            }
            .padding(.vertical, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(MDColor.paper.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(MDColor.life.opacity(0.35), lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mix your own color")
    }
}
