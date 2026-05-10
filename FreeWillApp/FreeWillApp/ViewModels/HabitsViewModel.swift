import Foundation

@Observable
class HabitsViewModel {
    var habitDays: [HabitDay] = []
    var todayHabits: HabitDay? = nil
    var isLoading = false
    var errorMessage: String? = nil

    private let api = APIService.shared

    var todayDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let all = api.fetchHabits()
            async let today = api.fetchTodayHabits()
            habitDays = try await all
            todayHabits = try await today
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(habit: String, completed: Bool) async {
        let date = todayDate
        do {
            try await api.toggleHabit(date: date, habit: habit, completed: completed)
            // Reload to reflect canonical state from server
            todayHabits = try await api.fetchTodayHabits()
            habitDays = try await api.fetchHabits()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var recentDays: [HabitDay] {
        Array(habitDays.suffix(7).reversed())
    }

    func streak(for habit: String) -> Int {
        var count = 0
        for day in habitDays.reversed() {
            if day.status(for: habit) == .done { count += 1 } else { break }
        }
        return count
    }
}
