import Foundation

struct TodoList: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String?
    /// A single emoji used as the list's icon. Takes precedence over `colorHex` when
    /// set; falls back to the colored dot (or default icon) when nil/empty.
    var emoji: String?
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String? = nil,
        emoji: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
