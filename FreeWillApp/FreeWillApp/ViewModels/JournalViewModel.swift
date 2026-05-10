import Foundation

@Observable
class JournalViewModel {
    var entries: [JournalEntry] = []
    var selectedEntry: JournalEntry? = nil
    var isLoading = false
    var errorMessage: String? = nil

    private let api = APIService.shared

    func loadEntries() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await api.fetchJournalList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadEntry(date: String) async {
        do {
            selectedEntry = try await api.fetchJournalEntry(date: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTodayEntry() async -> JournalEntry? {
        let today = ISO8601DateFormatter.localDate()
        do {
            let entry = try await api.createJournalEntry(date: today)
            entries.insert(entry, at: 0)
            return entry
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

private extension ISO8601DateFormatter {
    static func localDate() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
