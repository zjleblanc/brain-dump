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

                ForEach(store.lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
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
                            if selectedListID == list.id { selectedListID = nil }
                            store.delete(list)
                        }
                    }
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

// MARK: - Emoji / color picker row

/// Lets a list pick EITHER a single emoji icon OR fall back to a palette color.
/// Emoji takes visual precedence when set (see `listRow` above).
struct ListIconPickerView: View {
    @Binding var emoji: String?
    @Binding var colorHex: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick an emoji icon")
                .font(.caption)
                .foregroundStyle(.secondary)

            EmojiPickerView(selectedEmoji: $emoji)

            Text("Or pick a color (used when no emoji is set)")
                .font(.caption)
                .foregroundStyle(.secondary)

            SpectrumColorPickerView(selectedHex: $colorHex)
        }
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
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            TextField("List name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }
            ListIconPickerView(emoji: $emoji, colorHex: $colorHex)
            HStack {
                Button("Cancel") { onDismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { save() }.keyboardShortcut(.defaultAction).disabled(name.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 280)
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

    init(list: TodoList, onSave: @escaping (TodoList) -> Void, onDismiss: @escaping () -> Void) {
        _vs = StateObject(wrappedValue: ViewState(list: list))
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit List").font(.headline)
            TextField("List name", text: $vs.draft.name)
                .textFieldStyle(.roundedBorder)
            ListIconPickerView(emoji: $vs.draft.emoji, colorHex: $vs.draft.colorHex)
            HStack {
                Button("Cancel") { onDismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Done") {
                    onSave(vs.draft)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
