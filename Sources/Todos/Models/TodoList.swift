import Foundation

struct TodoList: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String?
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
