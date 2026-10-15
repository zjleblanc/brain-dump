import Foundation
import Combine

// MARK: - Persisted state

private struct StoreData: Codable {
    var items: [TodoItem] = []
    var lists: [TodoList] = []
    var tags: [Tag] = []
}

// MARK: - Store

/// Single source of truth for all todo data.
/// Persisted as JSON at ~/Library/Application Support/Todos/data.json.
final class TodoStore: ObservableObject {

    @Published var items: [TodoItem] = []
    @Published var lists: [TodoList] = []
    @Published var tags: [Tag] = []

    // MARK: Init / Persistence

    private static var dataURL: URL {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("Todos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("data.json")
    }

    private let saveURL: URL

    init() {
        saveURL = Self.dataURL
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let stored = try? JSONDecoder().decode(StoreData.self, from: data)
        else { return }
        items = stored.items
        lists = stored.lists
        tags  = stored.tags
    }

    func save() {
        let data = StoreData(items: items, lists: lists, tags: tags)
        try? JSONEncoder().encode(data).write(to: saveURL, options: .atomic)
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
            save()
        }
    }

    func deleteCompleted(in listID: UUID?) {
        items.removeAll { item in
            item.isCompleted && !item.isArchived &&
            (listID == nil || item.listID == listID)
        }
        save()
    }

    func clearArchive() {
        items.removeAll { $0.isArchived }
        save()
    }

    // MARK: - Lists

    func add(_ list: TodoList) {
        var l = list
        l.sortOrder = lists.count
        lists.append(l)
        save()
    }

    func update(_ list: TodoList) {
        if let idx = lists.firstIndex(where: { $0.id == list.id }) {
            lists[idx] = list
            save()
        }
    }

    func delete(_ list: TodoList) {
        for idx in items.indices where items[idx].listID == list.id {
            items[idx].listID = nil
        }
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
