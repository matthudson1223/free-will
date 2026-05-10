import SwiftUI

struct MessageBubble: View {
    let message: Message

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }

            Text(MarkdownRenderer.render(message.content))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if !isUser { Spacer(minLength: 48) }
        }
    }
}

struct StreamingBubble: View {
    let text: String
    let toolActivity: String?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                if let tool = toolActivity {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("Using \(tool)…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
                }
                if !text.isEmpty {
                    Text(MarkdownRenderer.render(text))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            Spacer(minLength: 48)
        }
    }
}
