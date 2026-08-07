import Foundation

enum ClientError: LocalizedError {
    case badResponse(String)
    case apiError(Int, String)
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .badResponse(let details): return "Bad response: \(details)"
        case .apiError(let code, let details): return "API error \(code): \(details)"
        case .emptyResult: return "Service returned empty output"
        }
    }
}

/// OpenAI-compatible API calls. Swift 5.3 has no async/await, so this uses
/// URLSession completion handlers.
final class DictationClient {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        return URLSession(configuration: config)
    }()

    /// POST {base}/audio/transcriptions with the audio file (multipart/form-data).
    /// If apiKey is empty, no Authorization header is sent (for local servers).
    func transcribe(
        audioURL: URL,
        baseURL: String,
        apiKey: String,
        model: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let endpoint = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines))
            .map({ $0.appendingPathComponent("audio/transcriptions") }) else {
            completion(.failure(ClientError.badResponse("invalid base URL")))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let filename = audioURL.lastPathComponent
        guard let audioData = try? Data(contentsOf: audioURL) else {
            completion(.failure(ClientError.badResponse("could not read recording")))
            return
        }

        var body = Data()
        func append(_ string: String) {
            body.append(string.data(using: .utf8)!)
        }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n\(model)\r\n")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: audio/mp4\r\n\r\n")
        body.append(audioData)
        append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(ClientError.badResponse("no HTTP response")))
                return
            }
            let bodyText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            guard http.statusCode == 200 else {
                completion(.failure(ClientError.apiError(http.statusCode, bodyText)))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String, !text.isEmpty else {
                completion(.failure(ClientError.emptyResult))
                return
            }
            completion(.success(text))
        }.resume()
    }

    /// POST {base}/chat/completions asking the LLM to clean the transcript.
    func clean(
        transcript: String,
        baseURL: String,
        apiKey: String,
        model: String,
        systemPrompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let endpoint = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines))
            .map({ $0.appendingPathComponent("chat/completions") }) else {
            completion(.failure(ClientError.badResponse("invalid base URL")))
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var payload: [String: Any] = [
            "temperature": 0,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": transcript]
            ]
        ]
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedModel.isEmpty {
            payload["model"] = trimmedModel
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(ClientError.badResponse("no HTTP response")))
                return
            }
            let bodyText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            guard http.statusCode == 200 else {
                completion(.failure(ClientError.apiError(http.statusCode, bodyText)))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let content = message["content"] as? String, !content.isEmpty else {
                completion(.failure(ClientError.emptyResult))
                return
            }
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "EMPTY" || trimmed.isEmpty {
                completion(.failure(ClientError.emptyResult))
            } else {
                completion(.success(trimmed))
            }
        }.resume()
    }
}
