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

/// Size chip with live tip preview circle (Small → Huge).
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
                        .frame(width: 48, height: 48)
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
                            width: min(size.width * 0.75, 32),
                            height: min(size.width * 0.75, 32)
                        )
                }
                Text(size.label)
                    .font(MDType.label(11))
                    .foregroundStyle(selected ? MDColor.ink : MDColor.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(size.label)
    }
}

/// Continuous opacity control — faint on the left, solid on the right.
struct OpacityScaleControl: View {
    @Binding var opacity: CGFloat
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                CheckerboardFill()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(opacity))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(MDColor.ink.opacity(0.12), lineWidth: 2)
            }
            .frame(height: 36)

            Slider(
                value: $opacity,
                in: OpacityScale.minimum...OpacityScale.maximum
            )
            .tint(MDColor.life)

            HStack {
                Text("Faint")
                    .font(MDType.label(12))
                    .foregroundStyle(MDColor.inkSoft)
                Spacer()
                Text("Solid")
                    .font(MDType.label(12))
                    .foregroundStyle(MDColor.inkSoft)
            }
        }
        .accessibilityLabel("Opacity")
        .accessibilityValue("\(Int((opacity * 100).rounded())) percent")
    }
}

/// Light checkerboard so see-through ink is obvious on paper.
private struct CheckerboardFill: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 8
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    let dark = (row + col) % 2 == 0
                    let rect = CGRect(x: x, y: y, width: cell, height: cell)
                    context.fill(
                        Path(rect),
                        with: .color(dark ? Color.black.opacity(0.08) : Color.white)
                    )
                    x += cell
                    col += 1
                }
                y += cell
                row += 1
            }
        }
        .background(MDColor.paper)
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

/// Opens the drawing tools menu (color, type, size, opacity).
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

/// Opens More Colors — gradient wheel + full crayon box.
struct MoreColorsButton: View {
    let current: Color
    let action: () -> Void

    private static let wheelColors: [Color] = [
        Color(red: 1, green: 0.2, blue: 0.3),
        Color(red: 1, green: 0.7, blue: 0.1),
        Color(red: 0.25, green: 0.85, blue: 0.35),
        Color(red: 0.2, green: 0.55, blue: 1),
        Color(red: 0.65, green: 0.3, blue: 0.95),
        Color(red: 1, green: 0.2, blue: 0.3)
    ]

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: Self.wheelColors,
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
                }
                Text("More Colors")
                    .font(MDType.label(10))
                    .foregroundStyle(MDColor.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: MDLayout.colorSwatch + 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More colors")
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

/// Kid-friendly hue wheel + brightness slider for More Colors.
struct GradientColorWheel: View {
    @Binding var color: Color
    var onPicked: (Color) -> Void

    @State private var hue: Double = 0
    @State private var saturation: Double = 0.85
    @State private var brightness: Double = 1
    @State private var didLoad = false

    private let wheelSize: CGFloat = 220

    private static let spectrum: [Color] = [
        Color(hue: 0.00, saturation: 1, brightness: 1),
        Color(hue: 0.08, saturation: 1, brightness: 1),
        Color(hue: 0.16, saturation: 1, brightness: 1),
        Color(hue: 0.33, saturation: 1, brightness: 1),
        Color(hue: 0.50, saturation: 1, brightness: 1),
        Color(hue: 0.66, saturation: 1, brightness: 1),
        Color(hue: 0.75, saturation: 1, brightness: 1),
        Color(hue: 0.83, saturation: 1, brightness: 1),
        Color(hue: 1.00, saturation: 1, brightness: 1)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick a color")
                .font(MDType.title(22))
                .foregroundStyle(MDColor.ink)
            Text("Drag on the wheel, then slide brightness.")
                .font(MDType.label(15))
                .foregroundStyle(MDColor.inkSoft)

            HStack {
                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: Self.spectrum,
                                center: .center
                            )
                        )

                    // White center → saturated rim
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, .white.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: wheelSize * 0.5
                            )
                        )

                    // Dim the whole wheel to preview brightness
                    Circle()
                        .fill(Color.black.opacity(max(0, 1 - brightness) * 0.85))
                        .allowsHitTesting(false)

                    Circle()
                        .strokeBorder(MDColor.paper, lineWidth: 6)
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                    wheelThumb
                }
                .frame(width: wheelSize, height: wheelSize)
                .clipShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateHS(from: value.location)
                        }
                )
                .accessibilityLabel("Color wheel")
                Spacer(minLength: 0)
            }

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(liveColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(MDColor.ink.opacity(0.15), lineWidth: 2)
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Brightness")
                            .font(MDType.label(13))
                            .foregroundStyle(MDColor.inkSoft)
                        Slider(value: $brightness, in: 0.15...1)
                            .tint(MDColor.life)
                            .onChange(of: brightness) { _, _ in
                                commitColor()
                            }
                    }
                }
            }
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
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            syncFromBoundColor()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("More colors wheel")
    }

    private var liveColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private var wheelThumb: some View {
        let radius = (wheelSize / 2) * saturation * 0.92
        // AngularGradient starts at top and runs clockwise — match thumb to that.
        let a = hue * 2 * .pi
        let x = sin(a) * radius
        let y = -cos(a) * radius
        return Circle()
            .fill(liveColor)
            .frame(width: 28, height: 28)
            .overlay(
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            .offset(x: x, y: y)
            .allowsHitTesting(false)
    }

    private func updateHS(from point: CGPoint) {
        let center = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        let maxR = wheelSize / 2
        guard distance > 2 else {
            saturation = 0
            commitColor()
            return
        }
        // 0 at north, clockwise — same as SwiftUI AngularGradient.
        var angle = atan2(dx, -dy)
        if angle < 0 { angle += 2 * .pi }
        hue = angle / (2 * .pi)
        saturation = min(max(distance / maxR, 0), 1)
        commitColor()
    }

    private func commitColor() {
        let next = liveColor
        color = next
        onPicked(next)
    }

    private func syncFromBoundColor() {
        let ui = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            hue = Double(h)
            saturation = Double(max(s, 0.05))
            brightness = Double(max(b, 0.15))
        }
    }
}
