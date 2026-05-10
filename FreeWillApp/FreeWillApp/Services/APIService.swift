import Foundation

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()

    var serverURL: String { (KeychainService.load("serverURL") ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
    var apiKey: String { KeychainService.load("apiKey") ?? "" }

    // MARK: - Generic request

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        let base = serverURL
        guard !base.isEmpty else { throw APIError.notConfigured }
        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        guard let url = URL(string: "\(trimmedBase)/\(path)") else { throw APIError.notConfigured }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.httpError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Health

    func checkHealth() async -> (success: Bool, error: String?) {
        do {
            let _: HealthResponse = try await request("health")
            return (true, nil)
        } catch {
            let errorMsg = "\(error)"
            print("❌ Health check failed: \(errorMsg)")
            return (false, errorMsg)
        }
    }

    // MARK: - Conversations

    func fetchConversations() async throws -> [Conversation] {
        try await request("conversations")
    }

    func createConversation(title: String = "New conversation") async throws -> Conversation {
        try await request("conversations", method: "POST", body: ["title": title])
    }

    func fetchMessages(conversationId: String) async throws -> [Message] {
        try await request("conversations/\(conversationId)/messages")
    }

    func renameConversation(id: String, title: String) async throws -> Conversation {
        try await request("conversations/\(id)", method: "PATCH", body: ["title": title])
    }

    // MARK: - Journal

    func fetchJournalList() async throws -> [JournalEntry] {
        try await request("journal")
    }

    func fetchJournalEntry(date: String) async throws -> JournalEntry {
        try await request("journal/\(date)")
    }

    func createJournalEntry(date: String, content: String = "") async throws -> JournalEntry {
        try await request("journal/\(date)", method: "POST", body: ["content": content])
    }

    // MARK: - Habits

    func fetchHabits() async throws -> [HabitDay] {
        try await request("habits")
    }

    func fetchTodayHabits() async throws -> HabitDay {
        try await request("habits/today")
    }

    func toggleHabit(date: String, habit: String, completed: Bool) async throws {
        let _: EmptyResponse = try await request(
            "habits/\(date)/\(habit)",
            method: "POST",
            body: ["completed": completed]
        )
    }

    // MARK: - Files

    func fetchFiles(path: String = "") async throws -> [FileItem] {
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        return try await request("files?path=\(encoded)")
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case notConfigured
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Server URL not configured. Go to Settings."
        case .httpError(let code): return "Server returned HTTP \(code)"
        }
    }
}

// MARK: - Helper types

private struct HealthResponse: Decodable { let status: String }
private struct EmptyResponse: Decodable {}
