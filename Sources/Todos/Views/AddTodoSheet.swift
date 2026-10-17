import SwiftUI

// MARK: - Add Todo Sheet

/// Slide-up creation form. Replaces the old "type title + auto-open edit modal" flow.
struct AddTodoSheet: View {
    @EnvironmentObject private var store: TodoStore

    final class ViewState: ObservableObject {
        @Published var draft: TodoItem
        @Published var hasDueDate: Bool

        init(title: String, listID: UUID?) {
            draft = TodoItem(title: title, listID: listID)
            hasDueDate = false
        }
    }

    @StateObject private var vs: ViewState
    @FocusState private var titleFocused: Bool

    var onSave: (TodoItem) -> Void
    var onDismiss: () -> Void

    init(
        initialTitle: String,
        defaultListID: UUID?,
        onSave: @escaping (TodoItem) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _vs = StateObject(wrappedValue: ViewState(title: initialTitle, listID: defaultListID))
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("New Todo").font(.headline)
                Spacer()
                Button("Add") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(vs.draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    addSection("Title") {
                        TextField("Todo title", text: $vs.draft.title, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor)))
                            .focused($titleFocused)
                            .onSubmit {
                                if !vs.draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
                                    save()
                                }
                            }
                    }

                    addSection("Notes") {
                        TextEditor(text: $vs.draft.notes)
                            .font(.system(size: 13))
                            .frame(minHeight: 60, maxHeight: 80)
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor)))
                            .scrollContentBackground(.hidden)
                    }

                    addSection("List") {
                        Picker("List", selection: $vs.draft.listID) {
                            Text("None").tag(Optional<UUID>.none)
                            ForEach(store.lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
                                Text(list.name).tag(Optional(list.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    addSection("Due Date") {
                        Toggle("Set due date", isOn: $vs.hasDueDate)
                            .toggleStyle(.switch)
                            .onChange(of: vs.hasDueDate) { _, new in
                                vs.draft.dueDate = new ? (vs.draft.dueDate ?? Date()) : nil
                            }
                        if vs.hasDueDate {
                            DatePicker(
                                "Due",
                                selection: Binding(
                                    get: { vs.draft.dueDate ?? Date() },
                                    set: { vs.draft.dueDate = $0 }
                                ),
                                displayedComponents: [.date]
                            )
                            .labelsHidden()
                            .datePickerStyle(.graphical)
                        }
                    }

                    addSection("Color") {
                        PalettePickerView(selectedHex: $vs.draft.colorHex)
                    }
                }
                .padding(16)
            }
        }
        .onAppear { titleFocused = true }
    }

    private func save() {
        let trimmed = vs.draft.title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        vs.draft.title = trimmed
        onSave(vs.draft)
    }

    @ViewBuilder
    private func addSection<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }
}
