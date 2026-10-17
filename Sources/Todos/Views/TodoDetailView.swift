import SwiftUI

struct TodoDetailView: View {
    @EnvironmentObject private var store: TodoStore

    final class ViewState: ObservableObject {
        @Published var draft: TodoItem
        @Published var hasDueDate: Bool
        @Published var showingAddTag = false
        @Published var newTagName = ""
        @Published var newTagColorHex: String?

        init(item: TodoItem) {
            draft = item
            hasDueDate = item.dueDate != nil
        }
    }

    @StateObject private var vs: ViewState

    var onSave: (TodoItem) -> Void
    var onDismiss: () -> Void

    init(item: TodoItem, onSave: @escaping (TodoItem) -> Void, onDismiss: @escaping () -> Void) {
        _vs = StateObject(wrappedValue: ViewState(item: item))
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    private var draftTags: [Tag] {
        store.tags.filter { vs.draft.tagIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 20) {
                // Left column: Title + Notes
                VStack(alignment: .leading, spacing: 20) {
                    section("Title") {
                        TextField("Todo title", text: $vs.draft.title, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor)))
                    }

                    section("Notes") {
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

                // Right column: List, Due Date, Color, Tags
                VStack(alignment: .leading, spacing: 20) {
                    section("List") {
                        Picker("List", selection: $vs.draft.listID) {
                            Text("None").tag(Optional<UUID>.none)
                            ForEach(store.lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
                                Text(list.name).tag(Optional(list.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    section("Due Date") {
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

                    section("Color") {
                        PalettePickerView(selectedHex: $vs.draft.colorHex)
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .frame(width: 520)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Edit Todo").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Delete Todo", role: .destructive) {
                    store.delete(vs.draft)
                    onDismiss()
                }
                .foregroundStyle(.red)

                Spacer()

                Button("Done") { save() }.keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
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
        onSave(vs.draft)
        onDismiss()
    }

    @ViewBuilder
    private func section<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }
}

// MARK: - Tag edit sheet

struct TagEditSheet: View {
    @Binding var name: String
    @Binding var colorHex: String?
    var onSave: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Tag").font(.headline)
            TextField("Tag name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }
            PalettePickerView(selectedHex: $colorHex)
            HStack {
                Button("Cancel") { onDismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") { save() }.keyboardShortcut(.defaultAction).disabled(name.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 260)
    }

    private func save() {
        guard !name.isEmpty else { return }
        onSave()
        onDismiss()
    }
}

// MARK: - Flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowHeight + spacing; x = 0; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
