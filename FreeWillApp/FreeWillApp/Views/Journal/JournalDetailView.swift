import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntry
    @State private var fullEntry: JournalEntry? = nil
    @State private var vm = JournalViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.displayDate)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                if let content = fullEntry?.content {
                    Text(MarkdownRenderer.render(content))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Loading entry…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.bottom, AppTheme.pagePadding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadEntry(date: entry.date)
            fullEntry = vm.selectedEntry
        }
    }
}
