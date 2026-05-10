import SwiftUI

struct MessageBubble: View {
    let message: Message

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if isUser {
                Text(MarkdownRenderer.render(message.content))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(ChatBubbleShape(isUser: true))
            } else {
                Text(MarkdownRenderer.render(message.content))
                    .padding(.leading, 4)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct StreamingBubble: View {
    let text: String
    let toolActivity: String?

    @State private var pulseOpacity: Double = 1

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                if let tool = toolActivity {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .opacity(pulseOpacity)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseOpacity)
                            .onAppear { pulseOpacity = 0.2 }
                        Text("Using \(tool)…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.surfaceDeep, in: Capsule())
                }
                if !text.isEmpty {
                    Text(MarkdownRenderer.render(text))
                        .padding(.leading, 4)
                        .foregroundStyle(.primary)
                }
            }
            Spacer(minLength: 60)
        }
    }
}
