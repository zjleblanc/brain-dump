import SwiftUI

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
