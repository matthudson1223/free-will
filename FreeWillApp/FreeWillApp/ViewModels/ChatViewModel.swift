import Foundation
import SwiftUI

@Observable
class ChatViewModel {
    var conversations: [Conversation] = []
    var selectedConversation: Conversation?
    var messages: [Message] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var streamingMessage: String = ""
    var toolActivity: String? = nil
    var errorMessage: String? = nil

    private let api = APIService.shared
    let ws = WebSocketService()

    init() {
        ws.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .textDelta(let chunk):
                self.streamingMessage += chunk
            case .toolUse(let name):
                self.toolActivity = name
            case .toolResult:
                self.toolActivity = nil
            case .done(let full):
                self.finishStreaming(text: full)
            case .error(let msg):
                self.isStreaming = false
                self.toolActivity = nil
                self.errorMessage = msg
            }
        }
    }

    func loadConversations() async {
        do {
            conversations = try await api.fetchConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectConversation(_ c: Conversation) {
        selectedConversation = c
        streamingMessage = ""
        Task {
            do {
                messages = try await api.fetchMessages(conversationId: c.id)
                await ws.connect(
                    conversationId: c.id,
                    serverURL: api.serverURL,
                    apiKey: api.apiKey
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func newConversation() async {
        do {
            let c = try await api.createConversation()
            conversations.insert(c, at: 0)
            selectConversation(c)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        inputText = ""
        isStreaming = true
        streamingMessage = ""

        // Optimistic user message
        let tempId = UUID().uuidString
        let userMsg = Message(
            id: tempId,
            conversationId: selectedConversation?.id ?? "",
            role: .user,
            content: text,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(userMsg)

        Task {
            await ws.send(text: text)
        }
    }

    private func finishStreaming(text: String) {
        let assistantMsg = Message(
            id: UUID().uuidString,
            conversationId: selectedConversation?.id ?? "",
            role: .assistant,
            content: text,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(assistantMsg)
        isStreaming = false
        streamingMessage = ""
        toolActivity = nil
    }
}
