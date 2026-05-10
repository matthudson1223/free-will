import Foundation

struct JournalEntry: Identifiable, Codable {
    var id: String { date }
    let date: String
    var content: String?
    var size: Int?

    var displayDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: date) else { return date }
        fmt.dateStyle = .long
        fmt.timeStyle = .none
        return fmt.string(from: d)
    }
}
