import Foundation
import SwiftUI

enum HabitStatus: String, Codable {
    case done, missed, na

    var symbol: String {
        switch self { case .done: "✓"; case .missed: "✗"; case .na: "—" }
    }
    var color: Color {
        switch self { case .done: .green; case .missed: .red; case .na: .secondary }
    }
}

struct HabitDay: Identifiable, Codable {
    var id: String { date }
    let date: String
    let phoneOutOfBed: HabitStatus
    let reflection: HabitStatus
    let morningBlock: HabitStatus
    let workCutoff: HabitStatus

    static let habitKeys: [(key: String, label: String)] = [
        ("phone_out_of_bed", "Phone out of bed"),
        ("reflection", "Reflection"),
        ("morning_block", "Morning block"),
        ("work_cutoff", "Work cutoff"),
    ]

    func status(for key: String) -> HabitStatus {
        switch key {
        case "phone_out_of_bed": phoneOutOfBed
        case "reflection": reflection
        case "morning_block": morningBlock
        case "work_cutoff": workCutoff
        default: .na
        }
    }
}
