import SwiftUI

struct ChatView: View {
    @State private var vm = ChatViewModel()

    var body: some View {
        NavigationSplitView {
            ConversationListView(vm: vm)
        } detail: {
            if let _ = vm.selectedConversation {
                MessageThreadView(vm: vm)
            } else {
                ContentUnavailableView(
                    "No conversation selected",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Tap + to start a new conversation")
                )
            }
        }
        .onChange(of: vm.selectedConversation) { _, new in
            if let c = new { vm.selectConversation(c) }
        }
        .task {
            await vm.loadConversations()
        }
    }
}
