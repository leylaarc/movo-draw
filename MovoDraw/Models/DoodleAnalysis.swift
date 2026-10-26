import SwiftUI
import UIKit

/// Lightweight local analysis of a kid doodle — colors + rough subject guess.
struct DoodleAnalysis: Sendable {
    let dominantColors: [UIColor]
    let subjectHint: SubjectHint
    let inkBounds: CGRect
    let strokeDensity: Double

    enum SubjectHint: String, Sendable {
        case flyer      // wings / tall / airborne silhouette → fly
        case creature   // blob with legs-ish → bounce / walk
        case vehicle    // wide / wheeled → glide
        case nature     // green/brown heavy → sway
        case mystery    // default gentle float
    }
}

struct LifeResult: Sendable {
    enum Kind: Sendable {
        case localAnimation(DoodleAnalysis)
        case remoteVideo(URL)
    }

    let kind: Kind
    let doodleImage: UIImage
    let safetyNotes: [String]
}
