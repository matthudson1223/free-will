import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(vm.goalCards) { card in
                        GoalCardView(card: card)
                    }
                }
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.vertical, 8)
            }
            .navigationTitle("Dashboard")
            .task { await vm.load() }
            .refreshable { await vm.load() }
        }
    }
}

struct GoalCardView: View {
    let card: GoalCard

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor)
                .frame(width: 3)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(card.icon)
                        .font(.title2)
                    Text(card.pillar)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Text(card.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                if !card.measure.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler")
                            .font(.caption2)
                        Text(card.measure)
                            .font(.caption2)
                            .lineLimit(2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
