import SwiftUI

struct MainContentView: View {
    @EnvironmentObject private var store: TodoStore

    final class ViewState: ObservableObject {
        @Published var selectedListID: UUID? = nil
        @Published var searchText: String = ""
        @Published var newTodoTitle: String = ""
        @Published var showingArchive: Bool = false
        @Published var selectedItem: TodoItem? = nil
    }
    @StateObject private var vs = ViewState()
    @FocusState private var quickAddFocused: Bool

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
                VStack(spacing: 0) {
                    ListSidebarView(selectedListID: $vs.selectedListID)
                    Spacer()
                }
                .frame(width: 140)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))

                Divider()

                // Main pane
                VStack(spacing: 0) {
                    SearchField(text: $vs.searchText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)

                    Divider()

                    TodoListPane(
                        selectedListID: vs.selectedListID,
                        searchText: vs.searchText
                    ) { vs.selectedItem = $0 }

                    Divider()
                    quickAddBar
                }
            }
        }
        .frame(width: 560, height: 480)
        .sheet(item: $vs.selectedItem) { item in
            TodoDetailView(item: item) { updated in
                store.update(updated)
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $vs.showingArchive) {
            ArchiveView()
                .environmentObject(store)
                .frame(width: 420, height: 500)
        }
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                if let hex = selectedList?.colorHex, let color = Color(hex: hex) {
                    Circle().fill(color).frame(width: 8, height: 8)
                } else {
                    Image(systemName: "tray").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Text(selectedList?.name ?? "All")
                    .font(.system(size: 13, weight: .semibold))
            }
            Spacer()
            Button { vs.showingArchive = true } label: {
                Image(systemName: "archivebox").font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("View Archive")

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
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.accentColor)
            TextField("Add a todo…", text: $vs.newTodoTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($quickAddFocused)
                .onSubmit { addTodo() }
            if !vs.newTodoTitle.isEmpty {
                Button("Add") { addTodo() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func addTodo() {
        let title = vs.newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        store.add(TodoItem(title: title, listID: vs.selectedListID))
        vs.newTodoTitle = ""
    }
}

// MARK: - Filtered todo list pane

struct TodoListPane: View {
    @EnvironmentObject private var store: TodoStore
    let selectedListID: UUID?
    let searchText: String
    var onSelect: (TodoItem) -> Void

    private var filtered: [TodoItem] {
        var result = store.items.filter { !$0.isArchived }
        if let id = selectedListID {
            result = result.filter { $0.listID == id }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.notes.lowercased().contains(q) ||
                store.tags(for: $0).contains(where: { $0.name.lowercased().contains(q) })
            }
        }
        return result.sorted { $0.createdAt > $1.createdAt }
    }

    private var active: [TodoItem]    { filtered.filter { !$0.isCompleted } }
    private var completed: [TodoItem] { filtered.filter { $0.isCompleted } }

    var body: some View {
        if filtered.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(active) { item in
                        TodoRowView(item: item) { onSelect(item) }
                        Divider().padding(.leading, 40)
                    }

                    if !completed.isEmpty {
                        Section {
                            ForEach(completed) { item in
                                TodoRowView(item: item) { onSelect(item) }
                                Divider().padding(.leading, 40)
                            }
                        } header: {
                            HStack {
                                Text("Completed · \(completed.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Clear") {
                                    store.deleteCompleted(in: selectedListID)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .buttonStyle(.plain)
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
            Text(searchText.isEmpty ? "Add a new todo below." : "Try a different search term.")
                .font(.caption).foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
