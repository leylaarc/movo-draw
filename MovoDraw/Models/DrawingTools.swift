import SwiftUI
import UIKit

// MARK: - Stroke style

enum StrokeStyle: String, CaseIterable, Identifiable {
    case pen
    case marker
    case crayon
    case eraser

    var id: String { rawValue }

    /// Short kid-facing label under the icon.
    var label: String {
        switch self {
        case .pen: return "Pen"
        case .marker: return "Marker"
        case .crayon: return "Crayon"
        case .eraser: return "Eraser"
        }
    }

    var systemImage: String {
        switch self {
        case .pen: return "pencil.tip"
        case .marker: return "highlighter"
        case .crayon: return "paintbrush.pointed"
        case .eraser: return "eraser"
        }
    }
}

// MARK: - Pen size (kid-friendly named sizes)

enum PenSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case jumbo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Thin"
        case .medium: return "Medium"
        case .large: return "Thick"
        case .jumbo: return "Jumbo"
        }
    }

    /// Tip diameter in points (fat for toddlers).
    var width: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 14
        case .large: return 26
        case .jumbo: return 42
        }
    }
}

// MARK: - Opacity presets

enum OpacityPreset: String, CaseIterable, Identifiable {
    case light
    case medium
    case solid

    var id: String { rawValue }

    /// Kid-friendly words — how “see-through” the stroke is.
    var label: String {
        switch self {
        case .light: return "Soft"
        case .medium: return "Medium"
        case .solid: return "Bold"
        }
    }

    var value: CGFloat {
        switch self {
        case .light: return 0.30
        case .medium: return 0.65
        case .solid: return 1.0
        }
    }
}

// MARK: - Persisted stroke

struct DoodleStroke {
    var color: UIColor
    var width: CGFloat
    var opacity: CGFloat
    var style: StrokeStyle
    var points: [CGPoint]
}

// MARK: - Active tool state (SwiftUI)

@MainActor
final class DrawingToolState: ObservableObject {
    @Published var color: UIColor = .black
    /// Bound to the system color picker (any custom mix).
    @Published var pickerColor: Color = .black
    @Published var size: PenSize = .medium
    @Published var opacity: OpacityPreset = .solid
    @Published var style: StrokeStyle = .pen
    /// Look tray (size + softness) starts open so specifics are obvious.
    @Published var trayExpanded = true
    @Published var showMoreColors = false
    @Published var showColorMixer = false

    var lineWidth: CGFloat { size.width }
    var opacityValue: CGFloat { opacity.value }

    var paintColor: UIColor {
        color.withAlphaComponent(opacityValue)
    }

    func selectCrayon(_ uiColor: UIColor) {
        color = uiColor
        pickerColor = Color(uiColor)
        if style == .eraser { style = .pen }
    }

    func applyPickerColor(_ newColor: Color) {
        pickerColor = newColor
        color = UIColor(newColor)
        if style == .eraser { style = .pen }
    }
}

// MARK: - Crayon entry + grouped palettes

struct CrayonColor: Identifiable, Hashable {
    let name: String
    let color: UIColor

    var id: String { name }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: CrayonColor, rhs: CrayonColor) -> Bool {
        lhs.name == rhs.name
    }
}

struct CrayonSection: Identifiable {
    let title: String
    let crayons: [CrayonColor]

    var id: String { title }
}

enum CrayonPalette {
    /// Always-visible dock row — core crayons kids reach for first (scrollable).
    static let primary: [CrayonColor] = [
        CrayonColor(name: "Black", color: .black),
        CrayonColor(name: "Red", color: UIColor(red: 0.92, green: 0.22, blue: 0.28, alpha: 1)),
        CrayonColor(name: "Orange", color: UIColor(red: 1.0, green: 0.52, blue: 0.18, alpha: 1)),
        CrayonColor(name: "Yellow", color: UIColor(red: 1.0, green: 0.82, blue: 0.18, alpha: 1)),
        CrayonColor(name: "Green", color: UIColor(red: 0.22, green: 0.72, blue: 0.42, alpha: 1)),
        CrayonColor(name: "Blue", color: UIColor(red: 0.22, green: 0.48, blue: 0.95, alpha: 1)),
        CrayonColor(name: "Purple", color: UIColor(red: 0.55, green: 0.38, blue: 0.92, alpha: 1)),
        CrayonColor(name: "Pink", color: UIColor(red: 1.0, green: 0.45, blue: 0.68, alpha: 1)),
        CrayonColor(name: "Brown", color: UIColor(red: 0.55, green: 0.35, blue: 0.18, alpha: 1)),
        CrayonColor(name: "White", color: UIColor(red: 0.98, green: 0.98, blue: 0.96, alpha: 1))
    ]

    /// Full crayon box — organized sections for the More sheet.
    static let sections: [CrayonSection] = [
        CrayonSection(title: "Bright", crayons: [
            CrayonColor(name: "Red", color: UIColor(red: 0.92, green: 0.22, blue: 0.28, alpha: 1)),
            CrayonColor(name: "Cherry", color: UIColor(red: 0.78, green: 0.10, blue: 0.22, alpha: 1)),
            CrayonColor(name: "Coral", color: UIColor(red: 1.0, green: 0.42, blue: 0.45, alpha: 1)),
            CrayonColor(name: "Orange", color: UIColor(red: 1.0, green: 0.52, blue: 0.18, alpha: 1)),
            CrayonColor(name: "Sunshine", color: UIColor(red: 1.0, green: 0.82, blue: 0.18, alpha: 1)),
            CrayonColor(name: "Gold", color: UIColor(red: 0.92, green: 0.72, blue: 0.12, alpha: 1)),
            CrayonColor(name: "Lime", color: UIColor(red: 0.62, green: 0.88, blue: 0.18, alpha: 1)),
            CrayonColor(name: "Green", color: UIColor(red: 0.22, green: 0.72, blue: 0.42, alpha: 1)),
            CrayonColor(name: "Blue", color: UIColor(red: 0.22, green: 0.48, blue: 0.95, alpha: 1)),
            CrayonColor(name: "Royal", color: UIColor(red: 0.18, green: 0.28, blue: 0.88, alpha: 1)),
            CrayonColor(name: "Purple", color: UIColor(red: 0.55, green: 0.38, blue: 0.92, alpha: 1)),
            CrayonColor(name: "Pink", color: UIColor(red: 1.0, green: 0.45, blue: 0.68, alpha: 1))
        ]),
        CrayonSection(title: "Soft", crayons: [
            CrayonColor(name: "Blush", color: UIColor(red: 1.0, green: 0.72, blue: 0.78, alpha: 1)),
            CrayonColor(name: "Peach", color: UIColor(red: 1.0, green: 0.78, blue: 0.62, alpha: 1)),
            CrayonColor(name: "Cream", color: UIColor(red: 1.0, green: 0.94, blue: 0.82, alpha: 1)),
            CrayonColor(name: "Butter", color: UIColor(red: 1.0, green: 0.94, blue: 0.55, alpha: 1)),
            CrayonColor(name: "Mint", color: UIColor(red: 0.55, green: 0.90, blue: 0.72, alpha: 1)),
            CrayonColor(name: "Sky", color: UIColor(red: 0.55, green: 0.78, blue: 0.98, alpha: 1)),
            CrayonColor(name: "Baby Blue", color: UIColor(red: 0.70, green: 0.85, blue: 0.98, alpha: 1)),
            CrayonColor(name: "Lavender", color: UIColor(red: 0.78, green: 0.68, blue: 0.95, alpha: 1)),
            CrayonColor(name: "Lilac", color: UIColor(red: 0.88, green: 0.78, blue: 0.95, alpha: 1)),
            CrayonColor(name: "Rose", color: UIColor(red: 0.95, green: 0.58, blue: 0.72, alpha: 1))
        ]),
        CrayonSection(title: "Skin", crayons: [
            CrayonColor(name: "Porcelain", color: UIColor(red: 0.98, green: 0.88, blue: 0.80, alpha: 1)),
            CrayonColor(name: "Fair", color: UIColor(red: 0.96, green: 0.80, blue: 0.68, alpha: 1)),
            CrayonColor(name: "Peachy", color: UIColor(red: 0.92, green: 0.70, blue: 0.55, alpha: 1)),
            CrayonColor(name: "Honey", color: UIColor(red: 0.86, green: 0.62, blue: 0.42, alpha: 1)),
            CrayonColor(name: "Tan", color: UIColor(red: 0.80, green: 0.58, blue: 0.42, alpha: 1)),
            CrayonColor(name: "Caramel", color: UIColor(red: 0.68, green: 0.45, blue: 0.30, alpha: 1)),
            CrayonColor(name: "Cocoa", color: UIColor(red: 0.52, green: 0.32, blue: 0.22, alpha: 1)),
            CrayonColor(name: "Espresso", color: UIColor(red: 0.36, green: 0.22, blue: 0.14, alpha: 1))
        ]),
        CrayonSection(title: "Earth", crayons: [
            CrayonColor(name: "Sand", color: UIColor(red: 0.88, green: 0.78, blue: 0.55, alpha: 1)),
            CrayonColor(name: "Tan Brown", color: UIColor(red: 0.78, green: 0.62, blue: 0.38, alpha: 1)),
            CrayonColor(name: "Brown", color: UIColor(red: 0.55, green: 0.35, blue: 0.18, alpha: 1)),
            CrayonColor(name: "Chocolate", color: UIColor(red: 0.42, green: 0.24, blue: 0.12, alpha: 1)),
            CrayonColor(name: "Forest", color: UIColor(red: 0.18, green: 0.48, blue: 0.28, alpha: 1)),
            CrayonColor(name: "Olive", color: UIColor(red: 0.48, green: 0.55, blue: 0.28, alpha: 1)),
            CrayonColor(name: "Teal", color: UIColor(red: 0.18, green: 0.68, blue: 0.68, alpha: 1)),
            CrayonColor(name: "Ocean", color: UIColor(red: 0.12, green: 0.42, blue: 0.62, alpha: 1)),
            CrayonColor(name: "Navy", color: UIColor(red: 0.15, green: 0.22, blue: 0.48, alpha: 1))
        ]),
        CrayonSection(title: "Neutrals", crayons: [
            CrayonColor(name: "White", color: UIColor(red: 0.98, green: 0.98, blue: 0.96, alpha: 1)),
            CrayonColor(name: "Silver", color: UIColor(red: 0.78, green: 0.80, blue: 0.84, alpha: 1)),
            CrayonColor(name: "Gray", color: UIColor(red: 0.55, green: 0.58, blue: 0.62, alpha: 1)),
            CrayonColor(name: "Charcoal", color: UIColor(red: 0.28, green: 0.30, blue: 0.34, alpha: 1)),
            CrayonColor(name: "Black", color: .black)
        ])
    ]

    static var allInSheet: [CrayonColor] {
        sections.flatMap(\.crayons)
    }
}
