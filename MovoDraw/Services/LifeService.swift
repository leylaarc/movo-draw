import Foundation
import UIKit

/// Pluggable “bring doodle to life” pipeline.
/// Swap `LocalDemoLifeService` for a cloud image-to-video model later.
protocol LifeService: Sendable {
    func bringToLife(_ image: UIImage) async throws -> LifeResult
}

enum LifeServiceError: LocalizedError {
    case emptyCanvas
    case unsafeContent
    case missingAPIKey
    case remoteFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyCanvas: return "Draw something first!"
        case .unsafeContent: return "Let's draw something friendly."
        case .missingAPIKey: return "No cloud API key — using local magic."
        case .remoteFailed(let msg): return msg
        }
    }
}

/// Factory: prefers cloud when keys exist, otherwise local demo.
enum LifeServiceFactory {
    static func make() -> any LifeService {
        if CloudLifeService.hasCredentials {
            return CloudLifeService()
        }
        return LocalDemoLifeService()
    }
}

/// Offline path: analyze doodle + return local animation instructions.
struct LocalDemoLifeService: LifeService {
    func bringToLife(_ image: UIImage) async throws -> LifeResult {
        try await Task.sleep(nanoseconds: 1_800_000_000) // kid-friendly “magic” beat
        let analysis = DoodleAnalyzer.analyze(image)
        let creative = SafetyFilter.creativePrompt(for: analysis)
        guard SafetyFilter.isSafe(creative) else {
            throw LifeServiceError.unsafeContent
        }
        _ = SafetyFilter.prompt(for: analysis) // full prompt ready for future cloud use
        return LifeResult(
            kind: .localAnimation(analysis),
            doodleImage: image,
            safetyNotes: ["Local demo animation", "Kid-safe prompt gated"]
        )
    }
}

/// Cloud stub — activates when `MOVO_DRAW_API_KEY` (or OpenAI / Replicate) is set.
/// Does not invent credentials; falls back is handled by the factory.
struct CloudLifeService: LifeService {
    static var hasCredentials: Bool {
        env("MOVO_DRAW_API_KEY") != nil
            || env("REPLICATE_API_TOKEN") != nil
            || env("OPENAI_API_KEY") != nil
            || env("RUNWAY_API_KEY") != nil
    }

    private static func env(_ key: String) -> String? {
        let value = ProcessInfo.processInfo.environment[key]
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    func bringToLife(_ image: UIImage) async throws -> LifeResult {
        let analysis = DoodleAnalyzer.analyze(image)
        let creative = SafetyFilter.creativePrompt(for: analysis)
        guard SafetyFilter.isSafe(creative) else {
            throw LifeServiceError.unsafeContent
        }
        let prompt = SafetyFilter.prompt(for: analysis)
        _ = prompt

        // Real provider wiring belongs here once a key + model are chosen.
        // For now: if a key exists but no provider adapter is configured,
        // fall through to the same local animation so the app never breaks.
        _ = Self.env("MOVO_DRAW_API_KEY")
            ?? Self.env("REPLICATE_API_TOKEN")
            ?? Self.env("OPENAI_API_KEY")
            ?? Self.env("RUNWAY_API_KEY")

        try await Task.sleep(nanoseconds: 1_200_000_000)
        return LifeResult(
            kind: .localAnimation(analysis),
            doodleImage: image,
            safetyNotes: [
                "API key detected — cloud adapter not yet configured; using local animation",
                "Prompt was kid-safety filtered"
            ]
        )
    }
}
