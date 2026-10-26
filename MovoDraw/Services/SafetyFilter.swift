import Foundation
import UIKit

/// Kid-safety gate for generative prompts (ages 2–12).
enum SafetyFilter {
    static let blockedTerms: Set<String> = [
        "blood", "gore", "kill", "murder", "weapon", "gun", "knife", "sword fight",
        "horror", "scary", "terror", "nightmare", "demon", "devil", "zombie",
        "nude", "naked", "sex", "sexual", "porn", "erotic",
        "drugs", "alcohol", "cigarette", "suicide", "hate"
    ]

    static let kidSafeStyleSuffix = """
    Style: cheerful, whimsical, child-friendly realism suitable for toddlers and kids ages 2–12. \
    Soft natural lighting, friendly expression, cute proportions, storybook-meets-photo look. \
    No violence, no horror, no weapons, no sexual content, no gore, no frightening faces, \
    no blood, no darkness, no adult themes.
    """

    static let negativePrompt = """
    horror, scary, terrifying, nightmare, gore, blood, violence, weapons, guns, knives, \
    demonic, evil, nude, nsfw, sexual, adult, drugs, dark, creepy, unsettling, mutilation
    """

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

    static func creativePrompt(for analysis: DoodleAnalysis) -> String {
        let colorWords = analysis.dominantColors.prefix(3).map(colorName).joined(separator: " and ")
        let subject: String
        switch analysis.subjectHint {
        case .flyer: subject = "friendly flying creature (like a gentle dragon or bird)"
        case .creature: subject = "friendly animal character"
        case .vehicle: subject = "cheerful toy-like vehicle"
        case .nature: subject = "happy plant or flower in a sunny garden"
        case .mystery: subject = "playful whimsical character"
        }
        return """
        Transform this child's crayon doodle into a single realistic but kid-safe illustration \
        of a \(colorWords) \(subject). Preserve the doodle's colors, silhouette, and intent. \
        Centered subject, clean background, high detail, photorealistic textures with soft \
        magical lighting. One clear character only.
        """
    }

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
