import Foundation

struct Conversation: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    let createdAt: String
    var updatedAt: String
}
