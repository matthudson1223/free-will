import SwiftUI

struct ConversationListView: View {
    @Bindable var vm: ChatViewModel

    var body: some View {
        Group {
            if vm.conversations.isEmpty {
                ContentUnavailableView(
                    "No conversations",
                    systemImage: "square.and.pencil",
                    description: Text("Tap the compose button to start")
                )
            } else {
                List(vm.conversations, selection: $vm.selectedConversation) { conv in
                    NavigationLink(value: conv) {
                        ConversationRow(conv: conv)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: AppTheme.pagePadding, bottom: 5, trailing: AppTheme.pagePadding))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await vm.newConversation() }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .task { await vm.loadConversations() }
        .refreshable { await vm.loadConversations() }
    }
}

private struct ConversationRow: View {
    let conv: Conversation

    private var relativeDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: conv.updatedAt)
        if date == nil {
            let f2 = ISO8601DateFormatter()
            date = f2.date(from: conv.updatedAt)
        }
        guard let date else { return "" }
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(conv.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(relativeDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
