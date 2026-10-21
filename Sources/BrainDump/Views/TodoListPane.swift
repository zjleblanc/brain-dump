import SwiftUI

// MARK: - Filtered todo list pane

struct TodoListPane: View {
    final class ViewState: ObservableObject {
        /// The item currently being dragged over; drives the drop-insertion
        /// indicator shown above that row.
        @Published var dragOverItemID: UUID?
    }

    @EnvironmentObject private var store: TodoStore
    @StateObject private var vs = ViewState()
    let selectedListID: UUID?
    let searchText: String
    /// Multi-select filter over `TodoStatus` — only items whose status is a member
    /// of this set are shown, split into a Todo / In Progress / Completed section.
    /// Defaults to Todo + In Progress upstream in `MainContentView.ViewState`.
    var statusFilter: Set<TodoStatus> = [.todo, .inProgress]
    /// Driven by the reorder-mode toggle hosted in `MainContentView`'s
    /// `statusFilterBar` (not this view) — shows a leading grip handle on each
    /// active row as a visual affordance for the (already-available)
    /// drag-to-reorder gesture. Mirrors `ListSidebarView`'s `isEditing`.
    @Binding var isEditing: Bool
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
        Self.reorderEnabled(selectedListID: selectedListID, searchText: searchText, statusFilter: statusFilter)
    }

    /// Standalone form of `reorderEnabled` so `MainContentView` — which hosts the
    /// reorder-mode toggle in its `statusFilterBar`, not this view — can decide
    /// whether to show that button (hidden entirely in the "All" view, while
    /// searching, or while Todo/In Progress is filtered out) without needing a
    /// `TodoListPane` instance.
    static func reorderEnabled(selectedListID: UUID?, searchText: String, statusFilter: Set<TodoStatus>) -> Bool {
        selectedListID != nil && searchText.isEmpty && statusFilter.isSuperset(of: [.todo, .inProgress])
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
        if nonCompletedSorted.isEmpty && completedItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    // Todo + In Progress — no header; the checkbox glyph (empty
                    // circle vs. half-filled) already distinguishes the two states.
                    ForEach(nonCompletedSorted) { item in
                        if vs.dragOverItemID == item.id {
                            dropIndicator
                        }
                        activeRow(item)
                        Divider()
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

    /// A thin accent-colored bar shown directly above a row while something is
    /// being dragged over it, indicating where the dropped item will land.
    private var dropIndicator: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(height: 2)
            .padding(.horizontal, 12)
            .transition(.opacity)
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
    /// Gains a leading grip handle while `isEditing`, matching `ListSidebarView`'s
    /// row treatment.
    @ViewBuilder
    private func activeRow(_ item: TodoItem) -> some View {
        let row = HStack(spacing: 0) {
            if reorderEnabled && isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 10)
            }
            TodoRowView(item: item) { onSelect(item) }
        }
        if reorderEnabled {
            row
                .draggable(item.id.uuidString)
                .dropDestination(for: String.self) { droppedIDs, _ in
                    handleDrop(droppedIDs, onto: item)
                } isTargeted: { targeted in
                    setDragTarget(item.id, isTargeted: targeted)
                }
        } else {
            row
        }
    }

    /// Updates `vs.dragOverItemID` from a row's `isTargeted` callback, ignoring a
    /// stale `false` for a different row than the one currently highlighted (can
    /// arrive after the next row's `true`, depending on drag timing).
    private func setDragTarget(_ id: UUID, isTargeted: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            vs.dragOverItemID = isTargeted ? id : (vs.dragOverItemID == id ? nil : vs.dragOverItemID)
        }
    }

    private func handleDrop(_ droppedIDs: [String], onto item: TodoItem) -> Bool {
        vs.dragOverItemID = nil
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
