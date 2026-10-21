import SwiftUI

struct ListSidebarView: View {
    @EnvironmentObject private var store: TodoStore
    @Binding var selectedListID: UUID?
    @Binding var showingAddList: Bool
    @Binding var editingList: TodoList?
    @Binding var newListName: String
    @Binding var newListColorHex: String?
    @Binding var newListEmoji: String?
    @Binding var showingArchive: Bool
    @Binding var confirmingDeleteList: TodoList?

    private var sortedLists: [TodoList] { store.lists.sorted(by: { $0.sortOrder < $1.sortOrder }) }

    /// Drag-to-reorder for user-created lists (the "All" row above is fixed and not
    /// part of this draggable group).
    private func handleListDrop(_ droppedIDs: [String], onto list: TodoList) -> Bool {
        let lists = sortedLists
        guard let draggedID = droppedIDs.first.flatMap(UUID.init(uuidString:)),
              let sourceIndex = lists.firstIndex(where: { $0.id == draggedID }),
              let destIndex = lists.firstIndex(where: { $0.id == list.id }),
              sourceIndex != destIndex
        else { return false }
        withAnimation(.spring(duration: 0.25)) {
            store.moveList(
                from: IndexSet(integer: sourceIndex),
                to: destIndex > sourceIndex ? destIndex + 1 : destIndex
            )
        }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                listRow(
                    label: "All",
                    systemIcon: "tray",
                    colorHex: nil,
                    emoji: nil,
                    count: store.activeItemCount,
                    isSelected: selectedListID == nil
                ) { selectedListID = nil }

                Divider().padding(.vertical, 2)

                ForEach(sortedLists) { list in
                    listRow(
                        label: list.name,
                        systemIcon: "list.bullet",
                        colorHex: list.colorHex,
                        emoji: list.emoji,
                        count: store.activeCount(in: list),
                        isSelected: selectedListID == list.id
                    ) { selectedListID = list.id }
                    .contextMenu {
                        Button("Edit") { withAnimation(.spring(duration: 0.3)) { editingList = list } }
                        Divider()
                        Button("Delete", role: .destructive) {
                            withAnimation(.spring(duration: 0.3)) { confirmingDeleteList = list }
                        }
                    }
                    .draggable(list.id.uuidString)
                    .dropDestination(for: String.self) { droppedIDs, _ in handleListDrop(droppedIDs, onto: list) }
                }
            }
            .padding(.vertical, 6)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button {
                    newListName = ""
                    newListColorHex = nil
                    newListEmoji = nil
                    withAnimation(.spring(duration: 0.3)) { showingAddList = true }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .help("New List")

                Spacer()

                Button {
                    withAnimation(.spring(duration: 0.3)) { showingArchive = true }
                } label: {
                    Image(systemName: "archivebox")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("View Archive")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func listRow(
        label: String,
        systemIcon: String,
        colorHex: String?,
        emoji: String?,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 13))
                        .frame(width: 16, height: 16)
                } else if let hex = colorHex, let color = Color(hex: hex) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: systemIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .frame(width: 16, height: 16)
                }
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6).fill(Color.accentColor)
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(Color.clear)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : .primary)
    }
}

// MARK: - New list sheet

struct ListEditSheet: View {
    @Binding var name: String
    @Binding var colorHex: String?
    @Binding var emoji: String?
    var title: String
    var onSave: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("List name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { save() }

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        EmojiPickerView(selectedEmoji: $emoji)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        SpectrumColorPickerView(selectedHex: $colorHex)
                        Text("Used when no emoji is set")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .frame(width: 440, height: 360)
        .safeAreaInset(edge: .top) {
            HStack {
                Button("Cancel") { onDismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Text(title).font(.headline)
                Spacer()
                Button("Save") { save() }.keyboardShortcut(.defaultAction).disabled(name.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    private func save() {
        guard !name.isEmpty else { return }
        onSave()
        onDismiss()
    }
}

// MARK: - Edit existing list sheet

struct ListEditSheetCopy: View {
    final class ViewState: ObservableObject {
        @Published var draft: TodoList

        init(list: TodoList) { draft = list }
    }

    @StateObject private var vs: ViewState

    var onSave: (TodoList) -> Void
    var onDismiss: () -> Void
    var onRequestDelete: () -> Void

    init(
        list: TodoList,
        onSave: @escaping (TodoList) -> Void,
        onDismiss: @escaping () -> Void,
        onRequestDelete: @escaping () -> Void
    ) {
        _vs = StateObject(wrappedValue: ViewState(list: list))
        self.onSave = onSave
        self.onDismiss = onDismiss
        self.onRequestDelete = onRequestDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("List name", text: $vs.draft.name)
                    .textFieldStyle(.roundedBorder)

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        EmojiPickerView(selectedEmoji: $vs.draft.emoji)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        SpectrumColorPickerView(selectedHex: $vs.draft.colorHex)
                        Text("Used when no emoji is set")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .frame(width: 440, height: 360)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Edit List").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Delete List", role: .destructive) {
                    onRequestDelete()
                }
                .foregroundStyle(.red)

                Spacer()

                Button("Done") {
                    onSave(vs.draft)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
}

// MARK: - Delete list confirmation

/// Shown before a list is deleted since deletion also permanently removes every
/// todo assigned to that list (see `TodoStore.delete(_:)`).
struct ListDeleteConfirmationView: View {
    @EnvironmentObject private var store: TodoStore
    let list: TodoList
    var onConfirm: () -> Void
    var onCancel: () -> Void

    private var affectedItems: [TodoItem] {
        store.items.filter { $0.listID == list.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Delete “\(list.name)”?").font(.headline)

            if affectedItems.isEmpty {
                Text("This list has no todos in it.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text(
                    "This list contains \(affectedItems.count) "
                        + (affectedItems.count == 1 ? "todo" : "todos")
                        + ". Deleting the list will also permanently delete "
                        + (affectedItems.count == 1 ? "it:" : "them:")
                )
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(affectedItems.prefix(5)) { item in
                        Text("•  \(item.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if affectedItems.count > 5 {
                        Text("…and \(affectedItems.count - 5) more")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
            }

            HStack {
                Button("Cancel") { onCancel() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Delete List", role: .destructive) { onConfirm() }
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
