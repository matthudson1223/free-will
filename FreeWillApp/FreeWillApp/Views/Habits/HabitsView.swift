import SwiftUI

struct HabitsView: View {
    @State private var vm = HabitsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, AppTheme.pagePadding)

                        VStack(spacing: 10) {
                            ForEach(HabitDay.habitKeys, id: \.key) { item in
                                HabitCard(
                                    label: item.label,
                                    status: vm.todayHabits?.status(for: item.key) ?? .na,
                                    streak: vm.streak(for: item.key)
                                ) { completed in
                                    Task { await vm.toggle(habit: item.key, completed: completed) }
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.pagePadding)
                    }

                    if !vm.recentDays.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Last 7 Days")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, AppTheme.pagePadding)

                            HabitHistoryGrid(days: vm.recentDays)
                                .padding(.horizontal, AppTheme.pagePadding)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Habits")
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }
}

struct HabitCard: View {
    let label: String
    let status: HabitStatus
    let streak: Int
    let onToggle: (Bool) -> Void

    @State private var pressing = false

    var dotColor: Color {
        switch status {
        case .done: return .green
        case .missed: return .red
        case .na: return Color(.systemGray4)
        }
    }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onToggle(status != .done)
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: status)

                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(streak)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }
}

struct HabitHistoryGrid: View {
    let days: [HabitDay]

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func dayAbbrev(from dateString: String) -> String {
        guard let date = dayFormatter.date(from: dateString) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(3))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days) { day in
                    VStack(spacing: 5) {
                        Text(dayAbbrev(from: day.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        ForEach(HabitDay.habitKeys, id: \.key) { item in
                            let s = day.status(for: item.key)
                            Circle()
                                .fill(s == .done ? Color.green : s == .missed ? Color.red : Color(.systemGray5))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
