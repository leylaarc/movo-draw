import Foundation
import UIKit

/// Secondary provider: OpenAI Images edits (`gpt-image-1`) with built-in moderation.
/// Used when `OPENAI_API_KEY` is set and no `FAL_KEY`.
struct OpenAIImageClient: Sendable {
    let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func generateRealisticImage(from doodle: UIImage, prompt: String) async throws -> UIImage {
        let resized = FalImageClient.resizeForUpload(doodle, maxSide: 1024)
        guard let png = resized.pngData() else {
            throw LifeServiceError.remoteFailed("Could not encode doodle PNG")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/edits")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        appendField("model", "gpt-image-1")
        appendField("prompt", prompt)
        appendField("size", "1024x1024")
        appendField("quality", "high")
        appendField("moderation", "auto")
        appendField("input_fidelity", "high")

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"doodle.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(png)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LifeServiceError.remoteFailed("No HTTP response from OpenAI")
        }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            if http.statusCode == 400, msg.lowercased().contains("safety") || msg.lowercased().contains("moderation") {
                throw LifeServiceError.unsafeContent
            }
            throw LifeServiceError.remoteFailed("OpenAI: \(msg.prefix(280))")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let items = json?["data"] as? [[String: Any]], let first = items.first else {
            throw LifeServiceError.remoteFailed("Unexpected OpenAI response")
        }
        if let b64 = first["b64_json"] as? String,
           let imageData = Data(base64Encoded: b64),
           let image = UIImage(data: imageData) {
            return image
        }
        if let urlString = first["url"] as? String, let url = URL(string: urlString) {
            let (imageData, _) = try await session.data(from: url)
            guard let image = UIImage(data: imageData) else {
                throw LifeServiceError.remoteFailed("Could not decode OpenAI image")
            }
            return image
        }
        throw LifeServiceError.remoteFailed("OpenAI response missing image")
    }
}
