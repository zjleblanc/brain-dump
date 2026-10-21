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
        @Published var statusFilter: Set<TodoStatus> = [.todo, .inProgress]
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
                        statusFilter: vs.statusFilter
                    ) { vs.selectedItem = $0 }

                    Divider()
                    statusFilterBar
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
                .help("Quit BrainDump")

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

    // MARK: Status filter bar

    /// Multi-select filter over `TodoStatus`, replacing the old binary "View
    /// Completed" toggle. Defaults to Todo + In Progress (set in `ViewState`); any
    /// combination may be selected, but at least one status must remain active so
    /// the list is never forced empty by the filter itself.
    private var statusFilterBar: some View {
        HStack(spacing: 6) {
            Spacer()
            ForEach([TodoStatus.todo, .inProgress, .completed], id: \.self) { status in
                statusFilterPill(status)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func statusFilterLabel(_ status: TodoStatus) -> String {
        switch status {
        case .todo: return "Todo"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    private func statusFilterPill(_ status: TodoStatus) -> some View {
        let isSelected = vs.statusFilter.contains(status)
        return Button {
            withAnimation(.spring(duration: 0.2)) {
                if isSelected {
                    // Keep at least one status selected so the filter can't hide
                    // every item.
                    guard vs.statusFilter.count > 1 else { return }
                    vs.statusFilter.remove(status)
                } else {
                    vs.statusFilter.insert(status)
                }
            }
        } label: {
            Text(statusFilterLabel(status))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                )
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
