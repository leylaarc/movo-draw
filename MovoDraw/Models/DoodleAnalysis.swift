import SwiftUI
import UIKit

/// Lightweight local analysis of a kid doodle — colors + rough subject guess.
struct DoodleAnalysis: Sendable {
    let dominantColors: [UIColor]
    let subjectHint: SubjectHint
    let inkBounds: CGRect
    let strokeDensity: Double

    enum SubjectHint: String, Sendable {
        case flyer
        case creature
        case vehicle
        case nature
        case mystery
    }
}

struct LifeResult: Sendable {
    enum Kind: Sendable {
        /// Primary path: realistic kid-safe image from the doodle.
        case generatedImage(UIImage)
        /// Secondary offline fallback only (no API key / network failure).
        case localFallback(DoodleAnalysis)
        case remoteVideo(URL)
    }

    let kind: Kind
    let doodleImage: UIImage
    let safetyNotes: [String]
    /// True when we used the offline SpriteKit path instead of cloud image gen.
    var isFallback: Bool {
        if case .localFallback = kind { return true }
        return false
    }
}
