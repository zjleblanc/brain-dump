import SwiftUI

struct MainContentView: View {
    @EnvironmentObject private var store: TodoStore

    final class ViewState: ObservableObject {
        @Published var selectedListID: UUID?
        @Published var searchText: String = ""
        @Published var newTodoTitle: String = ""
        @Published var showingArchive: Bool = false
        @Published var selectedItem: TodoItem?
        @Published var showingAddList = false
        @Published var editingList: TodoList?
        @Published var newListName = ""
        @Published var newListColorHex: String?
        @Published var newListEmoji: String?
        @Published var showingAddForm: Bool = false
        @Published var showingSettings: Bool = false
        @Published var showCompleted: Bool = false
        @Published var confirmingDeleteList: TodoList?
    }

    @StateObject private var vs = ViewState()

    private var selectedList: TodoList? {
        guard let id = vs.selectedListID else { return nil }
        return store.lists.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            HStack(spacing: 0) {
                // Sidebar
                ListSidebarView(
                    selectedListID: $vs.selectedListID,
                    showingAddList: $vs.showingAddList,
                    editingList: $vs.editingList,
                    newListName: $vs.newListName,
                    newListColorHex: $vs.newListColorHex,
                    newListEmoji: $vs.newListEmoji,
                    showingArchive: $vs.showingArchive,
                    confirmingDeleteList: $vs.confirmingDeleteList
                )
                .frame(width: 140)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))

                Divider()

                // Main pane
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        SearchField(text: $vs.searchText)
                        Button {
                            vs.newTodoTitle = ""
                            withAnimation(.spring(duration: 0.3)) { vs.showingAddForm = true }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                        .help("Add a Todo")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)

                    Divider()

                    TodoListPane(
                        selectedListID: vs.selectedListID,
                        searchText: vs.searchText,
                        showCompleted: vs.showCompleted
                    ) { vs.selectedItem = $0 }

                    Divider()
                    viewCompletedBar
                }
            }
        }
        .frame(width: 560, height: 480)
        .overlay {
            if let item = vs.selectedItem {
                BottomSheetContainer(
                    onEscape: { withAnimation(.spring(duration: 0.3)) { vs.selectedItem = nil } },
                    content: {
                        TodoDetailView(
                            item: item,
                            onSave: { updated in store.update(updated) },
                            onDismiss: { withAnimation(.spring(duration: 0.3)) { vs.selectedItem = nil } }
                        )
                        .environmentObject(store)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else if vs.showingAddForm {
                BottomSheetContainer(
                    onEscape: {
                        withAnimation(.spring(duration: 0.3)) {
                            vs.showingAddForm = false
                            vs.newTodoTitle = ""
                        }
                    },
                    content: {
                        AddTodoSheet(
                            initialTitle: vs.newTodoTitle,
                            defaultListID: vs.selectedListID,
                            onSave: { item in
                                store.add(item)
                                withAnimation(.spring(duration: 0.3)) {
                                    vs.showingAddForm = false
                                    vs.newTodoTitle = ""
                                }
                            },
                            onDismiss: {
                                withAnimation(.spring(duration: 0.3)) {
                                    vs.showingAddForm = false
                                    vs.newTodoTitle = ""
                                }
                            }
                        )
                        .environmentObject(store)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else if vs.showingAddList {
                BottomSheetContainer(
                    onEscape: { withAnimation(.spring(duration: 0.3)) { vs.showingAddList = false } },
                    content: {
                        ListEditSheet(
                            name: $vs.newListName,
                            colorHex: $vs.newListColorHex,
                            emoji: $vs.newListEmoji,
                            title: "New List",
                            onSave: {
                                store.add(TodoList(
                                    name: vs.newListName,
                                    colorHex: vs.newListColorHex,
                                    emoji: vs.newListEmoji
                                ))
                            },
                            onDismiss: { withAnimation(.spring(duration: 0.3)) { vs.showingAddList = false } }
                        )
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else if let list = vs.editingList {
                BottomSheetContainer(
                    onEscape: { withAnimation(.spring(duration: 0.3)) { vs.editingList = nil } },
                    content: {
                        ListEditSheetCopy(
                            list: list,
                            onSave: { updated in store.update(updated) },
                            onDismiss: { withAnimation(.spring(duration: 0.3)) { vs.editingList = nil } },
                            onRequestDelete: {
                                withAnimation(.spring(duration: 0.3)) {
                                    vs.editingList = nil
                                    vs.confirmingDeleteList = list
                                }
                            }
                        )
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else if vs.showingArchive {
                BottomSheetContainer(
                    onEscape: { withAnimation(.spring(duration: 0.3)) { vs.showingArchive = false } },
                    content: {
                        ArchiveView(onDismiss: { withAnimation(.spring(duration: 0.3)) { vs.showingArchive = false } })
                            .environmentObject(store)
                            .frame(height: 440)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else if vs.showingSettings {
                BottomSheetContainer(
                    onEscape: { withAnimation(.spring(duration: 0.3)) { vs.showingSettings = false } },
                    content: {
                        SettingsView(onDismiss: {
                            withAnimation(.spring(duration: 0.3)) { vs.showingSettings = false }
                        })
                        .environmentObject(store)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else if let list = vs.confirmingDeleteList {
                BottomSheetContainer(
                    onEscape: { withAnimation(.spring(duration: 0.3)) { vs.confirmingDeleteList = nil } },
                    content: {
                        ListDeleteConfirmationView(
                            list: list,
                            onConfirm: {
                                if vs.selectedListID == list.id { vs.selectedListID = nil }
                                store.delete(list)
                                withAnimation(.spring(duration: 0.3)) { vs.confirmingDeleteList = nil }
                            },
                            onCancel: { withAnimation(.spring(duration: 0.3)) { vs.confirmingDeleteList = nil } }
                        )
                        .environmentObject(store)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: Toolbar

    private var toolbar: some View {
        ZStack {
            // Centered regardless of the width of the leading/trailing buttons.
            HStack(spacing: 6) {
                if let emoji = selectedList?.emoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 12))
                } else if let hex = selectedList?.colorHex, let color = Color(hex: hex) {
                    Circle().fill(color).frame(width: 8, height: 8)
                } else {
                    Image(systemName: "tray").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Text(selectedList?.name ?? "All")
                    .font(.system(size: 13, weight: .semibold))
            }

            HStack {
                Button { NSApplication.shared.terminate(nil) } label: {
                    Image(systemName: "power").font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Quit Todos")

                Spacer()

                Button { withAnimation(.spring(duration: 0.3)) { vs.showingSettings = true } } label: {
                    Image(systemName: "gearshape").font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Settings")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: View Completed bar

    private var viewCompletedBar: some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { vs.showCompleted.toggle() }
        } label: {
            HStack(spacing: 8) {
                Spacer()
                Image(systemName: vs.showCompleted ? "eye.fill" : "eye.slash")
                    .font(.system(size: 14))
                    .foregroundStyle(vs.showCompleted ? Color.accentColor : .secondary)
                Text(vs.showCompleted ? "Hide Completed" : "View Completed")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func addTodo() {
        let title = vs.newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let item = TodoItem(title: title, listID: vs.selectedListID)
        store.add(item)
        vs.newTodoTitle = ""
    }
}

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

    private var active: [TodoItem] {
        baseItems.filter { !$0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
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
                        TodoRowView(item: item) { onSelect(item) }
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
