import Foundation
import Combine

// MARK: - Persisted state

private struct StoreData: Codable {
    var items: [TodoItem] = []
    var lists: [TodoList] = []
    var tags: [Tag] = []
    /// Optional so legacy data.json files (saved before Settings existed) decode fine.
    var settings: AppSettings?
}

// MARK: - Store

/// Single source of truth for all todo data.
/// Persisted as JSON at ~/Library/Application Support/BrainDump/data.json.
@MainActor
final class TodoStore: ObservableObject {

    @Published var items: [TodoItem] = []
    @Published var lists: [TodoList] = []
    @Published var tags: [Tag] = []
    @Published var settings: AppSettings = AppSettings()

    // MARK: Init / Persistence

    private static var dataURL: URL {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first! // swiftlint:disable:this force_unwrapping
        let dir = support.appendingPathComponent("BrainDump", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("data.json")
    }

    private let saveURL: URL
    private var purgeTimer: Timer?

    init() {
        saveURL = Self.dataURL
        load()
        purgeExpired()
        // Re-check retention policies periodically since this is a long-lived
        // menubar app that may stay open for days without a relaunch.
        purgeTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.purgeExpired() }
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let stored = try? JSONDecoder().decode(StoreData.self, from: data)
        else { return }
        items = stored.items
        lists = stored.lists
        tags  = stored.tags
        settings = stored.settings ?? AppSettings()

        // Backfill archivedAt for items archived before this field existed, so a
        // freshly-enabled retention policy doesn't immediately purge old data.
        var needsSave = false
        for idx in items.indices where items[idx].isArchived && items[idx].archivedAt == nil {
            items[idx].archivedAt = Date()
            needsSave = true
        }
        if needsSave { save() }
    }

    func save() {
        let data = StoreData(items: items, lists: lists, tags: tags, settings: settings)
        try? JSONEncoder().encode(data).write(to: saveURL, options: .atomic)
    }

    /// Permanently removes cleared/archived items older than their configured
    /// retention window. Items with no retention limit set (`nil` = Never) are kept.
    func purgeExpired() {
        let now = Date()
        var changed = false

        if let days = settings.clearedRetentionDays {
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? .distantPast
            let before = items.count
            items.removeAll { $0.isCleared && ($0.clearedAt ?? .distantFuture) < cutoff }
            changed = changed || items.count != before
        }

        if let days = settings.archivedRetentionDays {
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? .distantPast
            let before = items.count
            items.removeAll { $0.isArchived && ($0.archivedAt ?? .distantFuture) < cutoff }
            changed = changed || items.count != before
        }

        if changed { save() }
    }

    // MARK: - Computed helpers

    var activeItemCount: Int {
        items.filter { !$0.isCompleted && !$0.isArchived }.count
    }

    func activeCount(in list: TodoList) -> Int {
        items.filter { !$0.isCompleted && !$0.isArchived && $0.listID == list.id }.count
    }

    func tags(for item: TodoItem) -> [Tag] {
        tags.filter { item.tagIDs.contains($0.id) }
    }

    func list(for item: TodoItem) -> TodoList? {
        guard let id = item.listID else { return nil }
        return lists.first { $0.id == id }
    }

    // MARK: - Items

    func add(_ item: TodoItem) {
        items.insert(item, at: 0)
        save()
    }

    func update(_ item: TodoItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            save()
        }
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func toggleCompleted(_ item: TodoItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isCompleted.toggle()
            items[idx].completedAt = items[idx].isCompleted ? Date() : nil
            save()
        }
    }

    func toggleArchived(_ item: TodoItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isArchived.toggle()
            items[idx].archivedAt = items[idx].isArchived ? Date() : nil
            // Archiving supersedes the cleared bucket; drop any cleared timestamp
            // so the item doesn't show up with "Restore/Delete Permanently" actions.
            if items[idx].isArchived { items[idx].clearedAt = nil }
            save()
        }
    }

    /// Marks a completed item as cleared (hidden from the normal list, visible only
    /// via "View Cleared"). Called automatically after the row's delayed-clear timer.
    func clearItem(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        guard items[idx].isCompleted, !items[idx].isCleared else { return }
        items[idx].clearedAt = Date()
        save()
    }

    /// Un-clears an item, returning it to the normal completed list.
    func restoreCleared(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].clearedAt = nil
        save()
    }

    func clearArchive() {
        items.removeAll { $0.isArchived }
        save()
    }

    // MARK: - Lists

    func add(_ list: TodoList) {
        var newList = list
        newList.sortOrder = lists.count
        lists.append(newList)
        save()
    }

    func update(_ list: TodoList) {
        if let idx = lists.firstIndex(where: { $0.id == list.id }) {
            lists[idx] = list
            save()
        }
    }

    /// Count of todos that belong to `list` (active, completed, cleared, or
    /// archived) — used to summarize what a list deletion will also remove.
    func itemCount(in list: TodoList) -> Int {
        items.filter { $0.listID == list.id }.count
    }

    /// Deletes a list and every todo assigned to it. Callers should confirm with the
    /// user first (see `ListDeleteConfirmationView`) since this permanently removes
    /// the list's items rather than just unassigning them.
    func delete(_ list: TodoList) {
        items.removeAll { $0.listID == list.id }
        lists.removeAll { $0.id == list.id }
        save()
    }

    func moveList(from source: IndexSet, to destination: Int) {
        lists.move(fromOffsets: source, toOffset: destination)
        for i in lists.indices { lists[i].sortOrder = i }
        save()
    }

    // MARK: - Tags

    func add(_ tag: Tag) {
        tags.append(tag)
        save()
    }

    func update(_ tag: Tag) {
        if let idx = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[idx] = tag
            save()
        }
    }

    func delete(_ tag: Tag) {
        for idx in items.indices {
            items[idx].tagIDs.removeAll { $0 == tag.id }
        }
        tags.removeAll { $0.id == tag.id }
        save()
    }
}
