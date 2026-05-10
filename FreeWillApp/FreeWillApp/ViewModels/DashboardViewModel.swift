import Foundation

@Observable
class DashboardViewModel {
    var goals: [String: Any] = [:]
    var goalCards: [GoalCard] = []
    var isLoading = false

    private let api = APIService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await api.fetchGoals()
            goals = data
            goalCards = GoalCard.parse(from: data)
        } catch {}
    }
}

struct GoalCard: Identifiable {
    let id = UUID()
    let pillar: String
    let summary: String
    let measure: String
    let icon: String

    static let icons = ["balance": "⚖️", "habits": "🔁", "relationships": "🤝", "automation": "⚙️"]

    static func parse(from raw: [String: Any]) -> [GoalCard] {
        raw.compactMap { key, value in
            guard let dict = value as? [String: Any] else { return nil }
            let summary = (dict["summary"] as? String)
                ?? (dict["primary"] as? String)
                ?? key
            let measure = (dict["measured_by"] as? String)
                ?? (dict["measure"] as? String)
                ?? ""
            return GoalCard(
                pillar: key.capitalized,
                summary: summary,
                measure: measure,
                icon: icons[key] ?? "🎯"
            )
        }
        .sorted { $0.pillar < $1.pillar }
    }
}

extension APIService {
    func fetchGoals() async throws -> [String: Any] {
        guard let base = URL(string: serverURL) else { throw APIError.notConfigured }
        var req = URLRequest(url: base.appendingPathComponent("goals"))
        req.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}
