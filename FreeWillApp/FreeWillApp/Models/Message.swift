import Foundation

enum MessageRole: String, Codable {
    case user, assistant
}

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let role: MessageRole
    let content: String
    let createdAt: String
}
