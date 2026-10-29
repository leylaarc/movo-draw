import SwiftUI
import UIKit

// MARK: - Stroke style

enum StrokeStyle: String, CaseIterable, Identifiable {
    case pen
    case marker
    case crayon
    case eraser

    var id: String { rawValue }

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
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .jumbo: return "Jumbo"
        }
    }

    /// Tip diameter in points (fat for toddlers).
    var width: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 16
        case .large: return 28
        case .jumbo: return 44
        }
    }
}

// MARK: - Opacity presets

enum OpacityPreset: String, CaseIterable, Identifiable {
    case light
    case medium
    case solid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .solid: return "Solid"
        }
    }

    var value: CGFloat {
        switch self {
        case .light: return 0.35
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
    @Published var size: PenSize = .medium
    @Published var opacity: OpacityPreset = .solid
    @Published var style: StrokeStyle = .pen
    @Published var trayExpanded = false
    @Published var showMoreColors = false

    var lineWidth: CGFloat { size.width }
    var opacityValue: CGFloat { opacity.value }

    /// Effective paint color for non-eraser tools (alpha baked in for UIColor).
    var paintColor: UIColor {
        color.withAlphaComponent(opacityValue)
    }
}

// MARK: - Palettes

enum CrayonPalette {
    /// Always-visible row — primary crayons (not overwhelming).
    static let primary: [(name: String, color: UIColor)] = [
        ("Black", .black),
        ("Red", UIColor(red: 0.92, green: 0.22, blue: 0.28, alpha: 1)),
        ("Blue", UIColor(red: 0.22, green: 0.48, blue: 0.95, alpha: 1)),
        ("Yellow", UIColor(red: 1.0, green: 0.82, blue: 0.18, alpha: 1)),
        ("Green", UIColor(red: 0.22, green: 0.72, blue: 0.42, alpha: 1)),
        ("Orange", UIColor(red: 1.0, green: 0.52, blue: 0.18, alpha: 1)),
        ("Purple", UIColor(red: 0.55, green: 0.38, blue: 0.92, alpha: 1))
    ]

    /// Extra sheet — pastels, skin tones, browns, more brights.
    static let more: [(name: String, color: UIColor)] = [
        ("Pink", UIColor(red: 1.0, green: 0.55, blue: 0.72, alpha: 1)),
        ("Sky", UIColor(red: 0.55, green: 0.78, blue: 0.98, alpha: 1)),
        ("Mint", UIColor(red: 0.55, green: 0.90, blue: 0.72, alpha: 1)),
        ("Lavender", UIColor(red: 0.78, green: 0.68, blue: 0.95, alpha: 1)),
        ("Peach", UIColor(red: 1.0, green: 0.78, blue: 0.62, alpha: 1)),
        ("Cream", UIColor(red: 1.0, green: 0.94, blue: 0.82, alpha: 1)),
        ("Skin Light", UIColor(red: 0.96, green: 0.80, blue: 0.68, alpha: 1)),
        ("Skin Medium", UIColor(red: 0.80, green: 0.58, blue: 0.42, alpha: 1)),
        ("Skin Deep", UIColor(red: 0.48, green: 0.30, blue: 0.20, alpha: 1)),
        ("Brown", UIColor(red: 0.55, green: 0.35, blue: 0.18, alpha: 1)),
        ("Tan", UIColor(red: 0.78, green: 0.62, blue: 0.38, alpha: 1)),
        ("Gray", UIColor(red: 0.55, green: 0.58, blue: 0.62, alpha: 1)),
        ("White", UIColor(red: 0.98, green: 0.98, blue: 0.96, alpha: 1)),
        ("Teal", UIColor(red: 0.18, green: 0.68, blue: 0.68, alpha: 1)),
        ("Navy", UIColor(red: 0.15, green: 0.22, blue: 0.48, alpha: 1)),
        ("Coral", UIColor(red: 1.0, green: 0.42, blue: 0.45, alpha: 1))
    ]

    static var all: [(name: String, color: UIColor)] { primary + more }
}
