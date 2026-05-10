import SwiftUI

struct JournalView: View {
    @State private var vm = JournalViewModel()

    var body: some View {
        NavigationStack {
            List(vm.entries) { entry in
                NavigationLink(destination: JournalDetailView(entry: entry)) {
                    JournalEntryRow(entry: entry)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: AppTheme.pagePadding, bottom: 6, trailing: AppTheme.pagePadding))
            }
            .listStyle(.plain)
            .navigationTitle("Journal")
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Task { _ = await vm.createTodayEntry() }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
                }
                .padding(AppTheme.pagePadding)
            }
            .task { await vm.loadEntries() }
            .refreshable { await vm.loadEntries() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }
}

private struct JournalEntryRow: View {
    let entry: JournalEntry

    private var dayNumber: String {
        let parts = entry.date.split(separator: "-")
        return parts.count == 3 ? String(parts[2]).replacingOccurrences(of: "^0", with: "", options: .regularExpression) : "–"
    }

    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: entry.date) else { return "" }
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(monthYear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 64, alignment: .leading)

            Spacer()

            if let size = entry.size {
                Text(size < 1024 ? "<1 KB" : "\(size / 1024) KB")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
