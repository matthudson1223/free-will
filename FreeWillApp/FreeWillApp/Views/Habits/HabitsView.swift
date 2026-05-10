import SwiftUI

struct HabitsView: View {
    @State private var vm = HabitsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    ForEach(HabitDay.habitKeys, id: \.key) { item in
                        HabitToggleRow(
                            label: item.label,
                            status: vm.todayHabits?.status(for: item.key) ?? .na,
                            streak: vm.streak(for: item.key)
                        ) { completed in
                            Task { await vm.toggle(habit: item.key, completed: completed) }
                        }
                    }
                }

                if !vm.recentDays.isEmpty {
                    Section("Last 7 days") {
                        HabitHistoryGrid(days: vm.recentDays)
                    }
                }
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

struct HabitToggleRow: View {
    let label: String
    let status: HabitStatus
    let streak: Int
    let onToggle: (Bool) -> Void

    var body: some View {
        Button {
            onToggle(status != .done)
        } label: {
            HStack {
                Image(systemName: status == .done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(status.color)
                    .font(.title3)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if streak > 0 {
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

struct HabitHistoryGrid: View {
    let days: [HabitDay]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(days) { day in
                    VStack(spacing: 3) {
                        Text(day.date.suffix(5).replacingOccurrences(of: "-", with: "/"))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        ForEach(HabitDay.habitKeys, id: \.key) { item in
                            let s = day.status(for: item.key)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(s == .done ? Color.green : s == .missed ? Color.red : Color(.systemGray5))
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
