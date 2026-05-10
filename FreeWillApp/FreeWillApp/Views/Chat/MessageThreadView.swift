import SwiftUI

struct MessageThreadView: View {
    @Bindable var vm: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(vm.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if vm.isStreaming {
                            StreamingBubble(
                                text: vm.streamingMessage,
                                toolActivity: vm.toolActivity
                            )
                            .id("streaming")
                        }
                    }
                    .padding(.horizontal, AppTheme.pagePadding)
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.streamingMessage) {
                    withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                }
                .onChange(of: vm.messages.count) {
                    withAnimation { proxy.scrollTo(vm.messages.last?.id, anchor: .bottom) }
                }
            }

            ChatInputBar(
                text: $vm.inputText,
                isStreaming: vm.isStreaming,
                onSend: vm.sendMessage
            )
        }
        .navigationTitle(vm.selectedConversation?.title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
