import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @State private var habitsVm = HabitsViewModel()

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(vm.goalCards) { card in
                        GoalCardView(card: card)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .task {
                await vm.load()
                await habitsVm.load()
            }
            .refreshable {
                await vm.load()
                await habitsVm.load()
            }
        }
    }
}

struct GoalCardView: View {
    let card: GoalCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(card.icon)
                    .font(.title2)
                Text(card.pillar)
                    .font(.headline)
                    .lineLimit(1)
            }
            Text(card.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            if !card.measure.isEmpty {
                Divider()
                Label(card.measure, systemImage: "ruler")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
