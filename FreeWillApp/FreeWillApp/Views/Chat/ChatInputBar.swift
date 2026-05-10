import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit {
                    if !isStreaming { onSend() }
                }

            Button(action: onSend) {
                Image(systemName: isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(text.isEmpty && !isStreaming ? .gray : .blue)
            }
            .disabled(text.isEmpty && !isStreaming)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
