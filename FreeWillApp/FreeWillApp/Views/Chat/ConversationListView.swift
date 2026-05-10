import SwiftUI

struct ConversationListView: View {
    @Bindable var vm: ChatViewModel

    var body: some View {
        List(vm.conversations, selection: $vm.selectedConversation) { conv in
            NavigationLink(value: conv) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(conv.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(conv.updatedAt.prefix(10))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Conversations")
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
