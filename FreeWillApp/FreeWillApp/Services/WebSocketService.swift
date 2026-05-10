import Foundation

enum WSEvent {
    case textDelta(String)
    case toolUse(name: String)
    case toolResult(name: String, result: String)
    case done(fullText: String)
    case error(String)
}

@Observable
class WebSocketService {
    var streamingText: String = ""
    var isConnected: Bool = false
    var toolActivity: String? = nil

    private var task: URLSessionWebSocketTask?
    private var receiveLoop: Task<Void, Never>?
    var onEvent: ((WSEvent) -> Void)?

    func connect(conversationId: String, serverURL: String, apiKey: String) {
        disconnect()
        guard var comps = URLComponents(string: serverURL) else { return }
        comps.scheme = comps.scheme == "https" ? "wss" : "ws"
        comps.path = "/ws/chat/\(conversationId)"
        comps.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = comps.url else { return }

        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        startReceiving()
    }

    func disconnect() {
        receiveLoop?.cancel()
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
        streamingText = ""
        toolActivity = nil
    }

    func send(text: String) async {
        guard let task else { return }
        let payload = "{\"type\":\"message\",\"text\":\(encodeJSON(text))}"
        try? await task.send(.string(payload))
    }

    private func encodeJSON(_ s: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: s)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
    }

    private func startReceiving() {
        receiveLoop = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard let task = self.task else { break }
                do {
                    let msg = try await task.receive()
                    await MainActor.run { self.handle(msg) }
                } catch {
                    await MainActor.run {
                        self.isConnected = false
                        self.onEvent?(.error(error.localizedDescription))
                    }
                    break
                }
            }
        }
    }

    private func handle(_ msg: URLSessionWebSocketTask.Message) {
        guard case .string(let raw) = msg,
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "text_delta":
            let chunk = json["text"] as? String ?? ""
            streamingText += chunk
            onEvent?(.textDelta(chunk))

        case "tool_use":
            let name = json["name"] as? String ?? ""
            toolActivity = name
            onEvent?(.toolUse(name: name))

        case "tool_result":
            toolActivity = nil
            let name = json["name"] as? String ?? ""
            let result = json["result"] as? String ?? ""
            onEvent?(.toolResult(name: name, result: result))

        case "done":
            let full = json["text"] as? String ?? streamingText
            streamingText = ""
            toolActivity = nil
            onEvent?(.done(fullText: full))

        case "error":
            let msg = json["message"] as? String ?? "Unknown error"
            onEvent?(.error(msg))

        default:
            break
        }
    }
}
