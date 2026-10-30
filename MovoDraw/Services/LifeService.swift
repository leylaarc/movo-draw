import Foundation
import UIKit

/// Pluggable “bring doodle to life” pipeline.
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
        case .missingAPIKey: return "Picture magic isn’t set up yet. Ask a grown-up for help."
        case .remoteFailed(let msg): return msg
        }
    }
}

enum LifeServiceFactory {
    /// Prefer cloud image gen when a key exists; otherwise offline fallback.
    static func make() -> any LifeService {
        if APIKeyStore.hasAnyCloudKey() {
            return CloudLifeService()
        }
        return LocalDemoLifeService()
    }
}

/// Offline secondary path — demoted UI; only when no key / as last resort.
struct LocalDemoLifeService: LifeService {
    func bringToLife(_ image: UIImage) async throws -> LifeResult {
        try await Task.sleep(nanoseconds: 900_000_000)
        let analysis = DoodleAnalyzer.analyze(image)
        let creative = SafetyFilter.creativePrompt(for: analysis)
        guard SafetyFilter.isSafe(creative) else {
            throw LifeServiceError.unsafeContent
        }
        return LifeResult(
            kind: .localFallback(analysis),
            doodleImage: image,
            safetyNotes: [
                "Offline fallback (no API key)",
                "Parent: set FAL_KEY in the Xcode scheme for realistic images"
            ]
        )
    }
}

/// Cloud path: fal.ai FLUX Kontext (primary) or OpenAI Images edits (secondary).
struct CloudLifeService: LifeService {
    func bringToLife(_ image: UIImage) async throws -> LifeResult {
        let analysis = DoodleAnalyzer.analyze(image)
        let creative = SafetyFilter.creativePrompt(for: analysis)
        guard SafetyFilter.isSafe(creative) else {
            throw LifeServiceError.unsafeContent
        }
        let prompt = SafetyFilter.prompt(for: analysis)

        do {
            if let falKey = APIKeyStore.falKey() {
                let client = FalImageClient(apiKey: falKey)
                let generated = try await client.generateRealisticImage(from: image, prompt: prompt)
                return LifeResult(
                    kind: .generatedImage(generated),
                    doodleImage: image,
                    safetyNotes: [
                        "fal.ai FLUX Kontext",
                        "Kid-safe prompt + enable_safety_checker"
                    ]
                )
            }
            if let openAIKey = APIKeyStore.openAIKey() {
                let client = OpenAIImageClient(apiKey: openAIKey)
                let generated = try await client.generateRealisticImage(from: image, prompt: prompt)
                return LifeResult(
                    kind: .generatedImage(generated),
                    doodleImage: image,
                    safetyNotes: [
                        "OpenAI gpt-image-1 edits",
                        "moderation=auto + kid-safe prompt"
                    ]
                )
            }
            throw LifeServiceError.missingAPIKey
        } catch let error as LifeServiceError {
            if case .unsafeContent = error { throw error }
            // Network / provider failure → soft local fallback so the kid still gets something.
            let analysis = DoodleAnalyzer.analyze(image)
            return LifeResult(
                kind: .localFallback(analysis),
                doodleImage: image,
                safetyNotes: [
                    "Cloud failed — showing offline fallback",
                    error.localizedDescription
                ]
            )
        } catch {
            let analysis = DoodleAnalyzer.analyze(image)
            return LifeResult(
                kind: .localFallback(analysis),
                doodleImage: image,
                safetyNotes: [
                    "Cloud failed — showing offline fallback",
                    error.localizedDescription
                ]
            )
        }
    }
}
