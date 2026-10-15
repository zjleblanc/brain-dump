import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var isArchived: Bool
    var dueDate: Date?
    var colorHex: String?
    var listID: UUID?
    var tagIDs: [UUID]
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        colorHex: String? = nil,
        listID: UUID? = nil,
        tagIDs: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.isArchived = false
        self.dueDate = dueDate
        self.colorHex = colorHex
        self.listID = listID
        self.tagIDs = tagIDs
        self.createdAt = createdAt
        self.completedAt = nil
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }

    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
}
