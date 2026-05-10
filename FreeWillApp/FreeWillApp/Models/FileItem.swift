import Foundation

struct FileItem: Identifiable, Codable {
    var id: String { name }
    let name: String
    let type: String   // "file" | "dir"
    let size: Int?
    let modified: String

    var isDirectory: Bool { type == "dir" }
}
