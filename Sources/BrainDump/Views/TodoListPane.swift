import SwiftUI

// MARK: - Filtered todo list pane

struct TodoListPane: View {
    @EnvironmentObject private var store: TodoStore
    let selectedListID: UUID?
    let searchText: String
    /// Multi-select filter over `TodoStatus` — only items whose status is a member
    /// of this set are shown, split into a Todo / In Progress / Completed section.
    /// Defaults to Todo + In Progress upstream in `MainContentView.ViewState`.
    var statusFilter: Set<TodoStatus> = [.todo, .inProgress]
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
    /// unfiltered active-items group for the list. The same applies if either Todo
    /// or In Progress is hidden by `statusFilter`: `TodoStore.moveItem` always
    /// recomputes its reindex group from *all* non-completed items regardless of
    /// what's displayed, so hiding one of those statuses would desync the dragged
    /// row's on-screen index from the store's index.
    private var reorderEnabled: Bool {
        isSingleListView && searchText.isEmpty && statusFilter.isSuperset(of: [.todo, .inProgress])
    }

    /// Items matching the selected statuses, before splitting into per-status
    /// sections below.
    private var filteredItems: [TodoItem] {
        baseItems.filter { statusFilter.contains($0.status) }
    }

    /// Todo + In Progress items (whichever are selected in `statusFilter`),
    /// ordered the same way the old combined "active" list was: by manual
    /// `sortOrder` in a single-list view, by recency in the "All" view. Kept as one
    /// sorted list — rather than sorting `todoItems`/`inProgressItems`
    /// independently — so drag-to-reorder indices line up with `TodoStore
    /// .moveItem`'s shared sortOrder group across both statuses.
    private var nonCompletedSorted: [TodoItem] {
        let filtered = filteredItems.filter { $0.status != .completed }
        if isSingleListView {
            return filtered.sorted { $0.sortOrder < $1.sortOrder }
        }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    private var todoItems: [TodoItem] {
        nonCompletedSorted.filter { $0.status == .todo }
    }

    private var inProgressItems: [TodoItem] {
        nonCompletedSorted.filter { $0.status == .inProgress }
    }

    /// Completed tasks, whether still within the auto-clear delay window or already
    /// cleared — both are "completed tasks" from the user's perspective and are
    /// shown/hidden together via `statusFilter`.
    private var completedItems: [TodoItem] {
        filteredItems
            .filter { $0.status == .completed }
            .sorted { lhs, rhs in
                let lhsDate = lhs.clearedAt ?? lhs.completedAt ?? lhs.createdAt
                let rhsDate = rhs.clearedAt ?? rhs.completedAt ?? rhs.createdAt
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        if todoItems.isEmpty && inProgressItems.isEmpty && completedItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    // Todo — no header, matching the old unlabeled "active" section.
                    ForEach(todoItems) { item in
                        activeRow(item)
                        Divider()
                    }

                    if !inProgressItems.isEmpty {
                        Section {
                            ForEach(inProgressItems) { item in
                                activeRow(item)
                                Divider()
                            }
                        } header: {
                            sectionHeader("In Progress", count: inProgressItems.count)
                        }
                    }

                    if !completedItems.isEmpty {
                        Section {
                            ForEach(completedItems) { item in
                                TodoRowView(
                                    item: item,
                                    onTap: { onSelect(item) },
                                    onRestore: { store.restoreCleared(item) }
                                )
                                Divider()
                            }
                        } header: {
                            sectionHeader("Completed", count: completedItems.count)
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text("\(title) · \(count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.regularMaterial)
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
              let sourceIndex = nonCompletedSorted.firstIndex(where: { $0.id == draggedID }),
              let destIndex = nonCompletedSorted.firstIndex(where: { $0.id == item.id }),
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
