import SwiftUI

// MARK: - Add Todo Sheet

/// Slide-up creation form. Replaces the old "type title + auto-open edit modal" flow.
struct AddTodoSheet: View {
    @EnvironmentObject private var store: TodoStore

    final class ViewState: ObservableObject {
        @Published var draft: TodoItem
        @Published var hasDueDate: Bool
        @Published var showingAddTag = false
        @Published var newTagName = ""
        @Published var newTagColorHex: String?

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
                HStack(alignment: .top, spacing: 20) {
                    // Left column: Title + Notes
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
                                .frame(minHeight: 120, maxHeight: 220)
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(nsColor: .controlBackgroundColor)))
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right column: List, Tags, Due Date, Color
                    VStack(alignment: .leading, spacing: 20) {
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

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Tags")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                Spacer()
                                Button {
                                    vs.newTagName = ""
                                    vs.newTagColorHex = nil
                                    withAnimation(.spring(duration: 0.3)) { vs.showingAddTag = true }
                                } label: {
                                    Image(systemName: "plus.circle").font(.system(size: 13))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }

                            FlowLayout(spacing: 6) {
                                ForEach(store.tags.sorted(by: { $0.name < $1.name })) { tag in
                                    let isSelected = vs.draft.tagIDs.contains(tag.id)
                                    Button {
                                        if isSelected {
                                            vs.draft.tagIDs.removeAll { $0 == tag.id }
                                        } else {
                                            vs.draft.tagIDs.append(tag.id)
                                        }
                                    } label: {
                                        TagBadgeView(tag: tag)
                                            .overlay {
                                                if isSelected {
                                                    Capsule().stroke(Color.accentColor, lineWidth: 1.5)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if store.tags.isEmpty {
                                Text("No tags yet. Tap + to create one.")
                                    .font(.caption).foregroundStyle(.tertiary)
                            }
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
                            SpectrumColorPickerView(selectedHex: $vs.draft.colorHex)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
            }
        }
        .frame(width: 520)
        .onAppear { titleFocused = true }
        .overlay {
            if vs.showingAddTag {
                BottomSheetContainer(
                    onEscape: { withAnimation(.spring(duration: 0.3)) { vs.showingAddTag = false } },
                    content: {
                        TagEditSheet(
                            name: $vs.newTagName,
                            colorHex: $vs.newTagColorHex,
                            onSave: {
                                let tag = Tag(name: vs.newTagName, colorHex: vs.newTagColorHex)
                                store.add(tag)
                                vs.draft.tagIDs.append(tag.id)
                            },
                            onDismiss: {
                                withAnimation(.spring(duration: 0.3)) { vs.showingAddTag = false }
                            }
                        )
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
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
