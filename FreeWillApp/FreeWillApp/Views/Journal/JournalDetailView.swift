import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntry
    @State private var fullEntry: JournalEntry? = nil
    @State private var vm = JournalViewModel()

    var body: some View {
        ScrollView {
            if let content = fullEntry?.content {
                Text(MarkdownRenderer.render(content))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ProgressView()
                    .padding()
            }
        }
        .navigationTitle(entry.displayDate)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadEntry(date: entry.date)
            fullEntry = vm.selectedEntry
        }
    }
}
