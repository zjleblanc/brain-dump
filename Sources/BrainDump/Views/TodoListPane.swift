import SwiftUI

// MARK: - Filtered todo list pane

struct TodoListPane: View {
    @EnvironmentObject private var store: TodoStore
    let selectedListID: UUID?
    let searchText: String
    /// Open (active) tasks are always shown. This only controls whether the
    /// Completed section — including already auto-cleared items — is shown below them.
    var showCompleted: Bool = false
    var onSelect: (TodoItem) -> Void

    private var baseItems: [TodoItem] {
        var result = store.items.filter { !$0.isArchived }
        if let id = selectedListID {
            result = result.filter { $0.listID == id }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.notes.lowercased().contains(query) ||
                store.tags(for: $0).contains(where: { $0.name.lowercased().contains(query) })
            }
        }
        return result
    }

    /// Manual drag-to-reorder only makes sense when viewing a single list (sort
    /// order is scoped per-list) — the "All" view mixes items from every list and
    /// keeps the simpler recency ordering, with reordering disabled entirely.
    private var isSingleListView: Bool { selectedListID != nil }

    /// Reordering is additionally suspended while a search filter is active, since
    /// the filtered row indices wouldn't line up with `TodoStore.moveItem`'s
    /// unfiltered active-items group for the list.
    private var reorderEnabled: Bool { isSingleListView && searchText.isEmpty }

    private var active: [TodoItem] {
        let filtered = baseItems.filter { !$0.isCompleted }
        if isSingleListView {
            return filtered.sorted { $0.sortOrder < $1.sortOrder }
        }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    /// Completed tasks, whether still within the auto-clear delay window or already
    /// cleared — both are "completed tasks" from the user's perspective and are
    /// shown/hidden together via `showCompleted`.
    private var completed: [TodoItem] {
        baseItems
            .filter { $0.isCompleted }
            .sorted { lhs, rhs in
                let lhsDate = lhs.clearedAt ?? lhs.completedAt ?? lhs.createdAt
                let rhsDate = rhs.clearedAt ?? rhs.completedAt ?? rhs.createdAt
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        if active.isEmpty && (!showCompleted || completed.isEmpty) {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(active) { item in
                        activeRow(item)
                        Divider()
                    }

                    if showCompleted && !completed.isEmpty {
                        Section {
                            ForEach(completed) { item in
                                TodoRowView(
                                    item: item,
                                    onTap: { onSelect(item) },
                                    onRestore: { store.restoreCleared(item) }
                                )
                                Divider()
                            }
                        } header: {
                            HStack {
                                Text("Completed · \(completed.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(.regularMaterial)
                        }
                    }
                }
            }
        }
    }

    /// An active row, wrapped with drag-to-reorder support when `reorderEnabled` —
    /// dragging one row onto another moves it to that position within the list.
    @ViewBuilder
    private func activeRow(_ item: TodoItem) -> some View {
        let row = TodoRowView(item: item) { onSelect(item) }
        if reorderEnabled {
            row
                .draggable(item.id.uuidString)
                .dropDestination(for: String.self) { droppedIDs, _ in handleDrop(droppedIDs, onto: item) }
        } else {
            row
        }
    }

    private func handleDrop(_ droppedIDs: [String], onto item: TodoItem) -> Bool {
        guard let draggedID = droppedIDs.first.flatMap(UUID.init(uuidString:)),
              let sourceIndex = active.firstIndex(where: { $0.id == draggedID }),
              let destIndex = active.firstIndex(where: { $0.id == item.id }),
              sourceIndex != destIndex
        else { return false }
        withAnimation(.spring(duration: 0.25)) {
            store.moveItem(
                from: IndexSet(integer: sourceIndex),
                to: destIndex > sourceIndex ? destIndex + 1 : destIndex,
                inList: selectedListID
            )
        }
        return true
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "checkmark.circle" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "All done!" : "No results")
                .font(.headline).foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "+ Add a new todo" : "Try a different search term.")
                .font(.caption).foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
