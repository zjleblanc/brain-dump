import Foundation

/// The three states a todo can be in. Replaces the old `isCompleted: Bool` with a
/// richer lifecycle: `.todo` -> `.inProgress` -> `.completed`.
enum TodoStatus: String, Codable {
    case todo
    case inProgress
    case completed
}

struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var notes: String
    var status: TodoStatus
    var isArchived: Bool
    var dueDate: Date?
    var colorHex: String?
    var listID: UUID?
    var tagIDs: [UUID]
    var createdAt: Date
    var completedAt: Date?
    /// Set when the item's delayed auto-clear fires after being marked complete.
    /// Optional (rather than a plain Bool) so older persisted data decodes safely.
    var clearedAt: Date?
    /// Set when the item is archived; used to drive the "permanently delete archived
    /// after N days" retention setting. Optional for the same backward-compat reason.
    var archivedAt: Date?
    /// Position among sibling items that share the same `listID`, used for manual
    /// drag-to-reorder within a specific list. Not meaningful across lists (the "All"
    /// view sorts by `createdAt` instead and disables reordering).
    var sortOrder: Int

    private enum CodingKeys: String, CodingKey {
        case id, title, notes, status, isCompleted, isArchived, dueDate, colorHex
        case listID, tagIDs, createdAt, completedAt, clearedAt, archivedAt, sortOrder
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        colorHex: String? = nil,
        listID: UUID? = nil,
        tagIDs: [UUID] = [],
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.status = .todo
        self.isArchived = false
        self.dueDate = dueDate
        self.colorHex = colorHex
        self.listID = listID
        self.tagIDs = tagIDs
        self.createdAt = createdAt
        self.completedAt = nil
        self.clearedAt = nil
        self.archivedAt = nil
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        listID = try container.decodeIfPresent(UUID.self, forKey: .listID)
        tagIDs = try container.decode([UUID].self, forKey: .tagIDs)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        clearedAt = try container.decodeIfPresent(Date.self, forKey: .clearedAt)
        archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        // Older data has no sortOrder; TodoStore.load() backfills real values after
        // decoding, so 0 here is just a safe placeholder.
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        // Prefer the new `status` field; fall back to the legacy `isCompleted` bool
        // so data saved before this field existed decodes without data loss.
        if let decodedStatus = try container.decodeIfPresent(TodoStatus.self, forKey: .status) {
            status = decodedStatus
        } else {
            let legacyCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
            status = legacyCompleted ? .completed : .todo
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(status, forKey: .status)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(colorHex, forKey: .colorHex)
        try container.encodeIfPresent(listID, forKey: .listID)
        try container.encode(tagIDs, forKey: .tagIDs)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(clearedAt, forKey: .clearedAt)
        try container.encodeIfPresent(archivedAt, forKey: .archivedAt)
        try container.encode(sortOrder, forKey: .sortOrder)
    }

    /// Convenience accessor so existing call sites that treat completion as a bool
    /// keep working unchanged.
    var isCompleted: Bool { status == .completed }

    var isInProgress: Bool { status == .inProgress }

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }

    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }

    /// Whether this item's delayed auto-clear has fired. Cleared items are hidden
    /// from the normal active/completed list and only shown via "View Cleared".
    var isCleared: Bool { clearedAt != nil }
}
