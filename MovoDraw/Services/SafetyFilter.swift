import Foundation
import UIKit

/// Kid-safety gate for any generative / descriptive path.
/// Blocks scary, violent, sexual, or adult themes before prompts leave the device.
enum SafetyFilter {
    static let blockedTerms: Set<String> = [
        "blood", "gore", "kill", "murder", "weapon", "gun", "knife", "sword fight",
        "horror", "scary", "terror", "nightmare", "demon", "devil", "zombie",
        "nude", "naked", "sex", "sexual", "porn", "erotic",
        "drugs", "alcohol", "cigarette", "suicide", "hate"
    ]

    /// Soft rewrite rules so cloud prompts stay child-friendly.
    static let kidSafeStyleSuffix = """
    Style: cheerful children's illustration come to life, soft lighting, friendly expression, \
    age-appropriate for toddlers and kids ages 2–12. No violence, no horror, no weapons, \
    no sexual content, no gore, no scary faces.
    """

    /// Returns false only when the *creative* prompt contains blocked themes.
    /// The kid-safe style suffix is excluded so words like “scary” in “no scary faces” don’t false-positive.
    static func isSafe(_ text: String) -> Bool {
        let creative = text.components(separatedBy: "Style:").first ?? text
        let lowered = creative.lowercased()
        return !blockedTerms.contains { lowered.contains($0) }
    }

    static func sanitizePrompt(_ prompt: String) -> String {
        var cleaned = prompt
        for term in blockedTerms {
            cleaned = cleaned.replacingOccurrences(
                of: term,
                with: "",
                options: .caseInsensitive
            )
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" + kidSafeStyleSuffix
    }

    /// Creative prompt only (no style suffix) — used for the safety gate.
    static func creativePrompt(for analysis: DoodleAnalysis) -> String {
        let colorWords = analysis.dominantColors.prefix(3).map(colorName).joined(separator: " and ")
        let subject: String
        switch analysis.subjectHint {
        case .flyer: subject = "friendly flying creature"
        case .creature: subject = "friendly animal friend"
        case .vehicle: subject = "cheerful toy vehicle"
        case .nature: subject = "happy plant or flower"
        case .mystery: subject = "playful doodle character"
        }
        return "Bring this child's \(colorWords) \(subject) doodle to life with gentle looping motion."
    }

    /// Full prompt for cloud providers (creative + kid-safe style suffix).
    static func prompt(for analysis: DoodleAnalysis) -> String {
        sanitizePrompt(creativePrompt(for: analysis))
    }

    private static func colorName(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        if r > 0.55 && g < 0.35 && b < 0.35 { return "red" }
        if r < 0.25 && g < 0.25 && b < 0.25 { return "black" }
        if r > 0.7 && g > 0.7 && b < 0.35 { return "yellow" }
        if r < 0.35 && g > 0.5 && b < 0.45 { return "green" }
        if r < 0.4 && g < 0.55 && b > 0.7 { return "blue" }
        if r > 0.55 && g < 0.45 && b > 0.55 { return "purple" }
        if r > 0.7 && g > 0.45 && b < 0.35 { return "orange" }
        return "colorful"
    }
}
