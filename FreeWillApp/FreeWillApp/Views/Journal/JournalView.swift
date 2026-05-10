import SwiftUI

struct JournalView: View {
    @State private var vm = JournalViewModel()

    var body: some View {
        NavigationStack {
            List(vm.entries) { entry in
                NavigationLink(destination: JournalDetailView(entry: entry)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.displayDate)
                            .font(.headline)
                        if let size = entry.size {
                            Text("\(size / 1024 == 0 ? "<1" : "\(size/1024)") KB")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Journal")
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Task {
                        if let entry = await vm.createTodayEntry() {
                            // Selection handled by NavigationStack push below
                            _ = entry
                        }
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(20)
            }
            .task { await vm.loadEntries() }
            .refreshable { await vm.loadEntries() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }
}
