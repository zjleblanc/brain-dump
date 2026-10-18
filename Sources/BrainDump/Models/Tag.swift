import Foundation

struct Tag: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
