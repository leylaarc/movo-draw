import Foundation
import UIKit

/// fal.ai FLUX Kontext — doodle image + kid-safe prompt → realistic image.
/// Docs: https://fal.ai/models/fal-ai/flux-kontext/dev/api
struct FalImageClient: Sendable {
    /// Dev endpoint: good quality, lower cost for MVP. Swap to `fal-ai/flux-pro/kontext` for max quality.
    static let modelPath = "fal-ai/flux-kontext/dev"

    let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func generateRealisticImage(from doodle: UIImage, prompt: String) async throws -> UIImage {
        let dataURI = try Self.pngDataURI(doodle)
        // flux-kontext/dev: prompt + image_url are required; keep optional fields conservative.
        let body: [String: Any] = [
            "prompt": prompt,
            "image_url": dataURI,
            "num_images": 1,
            "output_format": "png",
            "guidance_scale": 3.5
        ]

        // Prefer sync fal.run; fall back to queue if needed.
        if let image = try await runSync(body: body) {
            return image
        }
        return try await runQueued(body: body)
    }

    // MARK: - Sync

    private func runSync(body: [String: Any]) async throws -> UIImage? {
        let url = URL(string: "https://fal.run/\(Self.modelPath)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LifeServiceError.remoteFailed("No HTTP response from fal.ai")
        }
        // 200 = sync result; 4xx/5xx = error; some accounts redirect to queue
        if http.statusCode == 200 {
            return try await decodeImage(from: data)
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw LifeServiceError.remoteFailed("fal.ai rejected the API key (\(http.statusCode))")
        }
        // Fall through to queue for 202 / other
        if (200..<300).contains(http.statusCode) == false && http.statusCode != 202 {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            // Try queue path for temporary errors
            if http.statusCode >= 500 { return nil }
            throw LifeServiceError.remoteFailed("fal.ai: \(msg.prefix(280))")
        }
        return nil
    }

    // MARK: - Queue

    private func runQueued(body: [String: Any]) async throws -> UIImage {
        let submitURL = URL(string: "https://queue.fal.run/\(Self.modelPath)")!
        var submit = URLRequest(url: submitURL)
        submit.httpMethod = "POST"
        submit.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        submit.setValue("application/json", forHTTPHeaderField: "Content-Type")
        submit.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (submitData, submitResponse) = try await session.data(for: submit)
        guard let http = submitResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: submitData, encoding: .utf8) ?? "submit failed"
            throw LifeServiceError.remoteFailed("fal.ai queue: \(msg.prefix(280))")
        }

        let submitJSON = try JSONSerialization.jsonObject(with: submitData) as? [String: Any]
        guard let requestId = submitJSON?["request_id"] as? String else {
            throw LifeServiceError.remoteFailed("fal.ai queue missing request_id")
        }

        let statusURL = URL(string: "https://queue.fal.run/\(Self.modelPath)/requests/\(requestId)/status")!
        let resultURL = URL(string: "https://queue.fal.run/\(Self.modelPath)/requests/\(requestId)")!

        for _ in 0..<60 {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            var statusReq = URLRequest(url: statusURL)
            statusReq.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
            let (statusData, _) = try await session.data(for: statusReq)
            let statusJSON = try JSONSerialization.jsonObject(with: statusData) as? [String: Any]
            let status = (statusJSON?["status"] as? String) ?? ""
            if status == "COMPLETED" {
                var resultReq = URLRequest(url: resultURL)
                resultReq.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
                let (resultData, _) = try await session.data(for: resultReq)
                return try await decodeImage(from: resultData)
            }
            if status == "FAILED" || status == "CANCELLED" {
                throw LifeServiceError.remoteFailed("fal.ai generation \(status.lowercased())")
            }
        }
        throw LifeServiceError.remoteFailed("fal.ai timed out")
    }

    // MARK: - Decode

    private func decodeImage(from data: Data) async throws -> UIImage {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let nsfw = json?["has_nsfw_concepts"] as? [Bool], nsfw.contains(true) {
            throw LifeServiceError.unsafeContent
        }
        guard let images = json?["images"] as? [[String: Any]],
              let first = images.first,
              let urlString = first["url"] as? String else {
            let preview = String(data: data, encoding: .utf8)?.prefix(200) ?? "…"
            throw LifeServiceError.remoteFailed("Unexpected fal.ai response: \(preview)")
        }

        if urlString.hasPrefix("data:image") {
            return try Self.imageFromDataURI(urlString)
        }
        guard let url = URL(string: urlString) else {
            throw LifeServiceError.remoteFailed("Invalid image URL from fal.ai")
        }
        let (imageData, _) = try await session.data(from: url)
        guard let image = UIImage(data: imageData) else {
            throw LifeServiceError.remoteFailed("Could not decode generated image")
        }
        return image
    }

    static func pngDataURI(_ image: UIImage) throws -> String {
        let resized = resizeForUpload(image, maxSide: 1024)
        guard let png = resized.pngData() else {
            throw LifeServiceError.remoteFailed("Could not encode doodle PNG")
        }
        return "data:image/png;base64,\(png.base64EncodedString())"
    }

    static func imageFromDataURI(_ uri: String) throws -> UIImage {
        guard let comma = uri.firstIndex(of: ",") else {
            throw LifeServiceError.remoteFailed("Bad data URI")
        }
        let b64 = String(uri[uri.index(after: comma)...])
        guard let data = Data(base64Encoded: b64), let image = UIImage(data: data) else {
            throw LifeServiceError.remoteFailed("Bad data URI image")
        }
        return image
    }

    static func resizeForUpload(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return image }
        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
