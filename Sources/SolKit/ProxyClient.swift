import Foundation

/// Calls the Sol proxy (Phase 0). Sends 16 kHz mono WAV + the language + bearer token to
/// POST /v1/transcribe and returns clean text. Used by both the app and the keyboard extension.
public struct ProxyClient {
    public struct Result: Decodable {
        public let text: String
        public let language: String
        public let cleaned: Bool
    }

    enum ProxyError: Error { case badStatus(Int), emptyAudio }

    private let config: SolConfig
    private let session: URLSession

    public init(config: SolConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func transcribe(wav: Data, language: String? = nil) async throws -> Result {
        guard !wav.isEmpty else { throw ProxyError.emptyAudio }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: config.proxyURL.appendingPathComponent("v1/transcribe"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if !config.token.isEmpty {
            request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        // audio part
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"clip.wav\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append(wav)
        body.append("\r\n")
        field("language", language ?? config.language)
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(status) else { throw ProxyError.badStatus(status) }
        return try JSONDecoder().decode(Result.self, from: data)
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) { append(d) }
    }
}
