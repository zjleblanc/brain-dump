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
        @Published var viewingCleared: Bool = false
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
                    showingArchive: $vs.showingArchive
                )
                .frame(width: 140)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))

                Divider()

                // Main pane
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        SearchField(
                            text: $vs.searchText,
                            placeholder: vs.viewingCleared ? "Search cleared…" : "Search"
                        )
                        Button {
                            withAnimation(.spring(duration: 0.25)) { vs.viewingCleared.toggle() }
                        } label: {
                            Image(systemName: vs.viewingCleared ? "eye.fill" : "eye.slash")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(vs.viewingCleared ? Color.accentColor : .secondary)
                        .help(vs.viewingCleared ? "Hide Cleared Items" : "View Cleared Items")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)

                    Divider()

                    TodoListPane(
                        selectedListID: vs.selectedListID,
                        searchText: vs.searchText,
                        viewingCleared: vs.viewingCleared
                    ) { vs.selectedItem = $0 }

                    if !vs.viewingCleared {
                        Divider()
                        quickAddBar
                    }
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
                            onDismiss: { withAnimation(.spring(duration: 0.3)) { vs.editingList = nil } }
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
            }
        }
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
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
            Spacer()
            Button { withAnimation(.spring(duration: 0.3)) { vs.showingSettings = true } } label: {
                Image(systemName: "gearshape").font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Settings")

            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power").font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Quit Todos")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: Quick-add bar

    private var quickAddBar: some View {
        Button {
            vs.newTodoTitle = ""
            withAnimation(.spring(duration: 0.3)) { vs.showingAddForm = true }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentColor)
                Text("Add a todo…")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
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
    /// When true, shows only cleared (auto-cleared completed) items instead of the
    /// normal active/completed list.
    var viewingCleared: Bool = false
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

    private var filtered: [TodoItem] {
        baseItems.filter { !$0.isCleared }.sorted { $0.createdAt > $1.createdAt }
    }

    private var clearedItems: [TodoItem] {
        baseItems
            .filter { $0.isCleared }
            .sorted { ($0.clearedAt ?? $0.createdAt) > ($1.clearedAt ?? $1.createdAt) }
    }

    private var active: [TodoItem] { filtered.filter { !$0.isCompleted } }
    private var completed: [TodoItem] { filtered.filter { $0.isCompleted } }

    var body: some View {
        if viewingCleared {
            clearedListView
        } else if filtered.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(active) { item in
                        TodoRowView(item: item) { onSelect(item) }
                        Divider()
                    }

                    if !completed.isEmpty {
                        Section {
                            ForEach(completed) { item in
                                TodoRowView(item: item) { onSelect(item) }
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

    @ViewBuilder
    private var clearedListView: some View {
        if clearedItems.isEmpty {
            clearedEmptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(clearedItems) { item in
                        TodoRowView(
                            item: item,
                            onTap: { onSelect(item) },
                            onRestore: { store.restoreCleared(item) }
                        )
                        Divider()
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
            Text(searchText.isEmpty ? "Add a new todo below." : "Try a different search term.")
                .font(.caption).foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var clearedEmptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "eye.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No Cleared Items").font(.headline).foregroundStyle(.secondary)
            Text("Todos you complete are cleared here automatically.")
                .font(.caption).foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
