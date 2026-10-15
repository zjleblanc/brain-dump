import SwiftUI

struct ListSidebarView: View {
    @EnvironmentObject private var store: TodoStore
    @Binding var selectedListID: UUID?

    final class ViewState: ObservableObject {
        @Published var showingAddList = false
        @Published var editingList: TodoList? = nil
        @Published var newListName = ""
        @Published var newListColorHex: String? = nil
    }
    @StateObject private var vs = ViewState()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            listRow(
                label: "All",
                systemIcon: "tray",
                colorHex: nil,
                count: store.activeItemCount,
                isSelected: selectedListID == nil
            ) { selectedListID = nil }

            Divider().padding(.vertical, 2)

            ForEach(store.lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
                listRow(
                    label: list.name,
                    systemIcon: "list.bullet",
                    colorHex: list.colorHex,
                    count: store.activeCount(in: list),
                    isSelected: selectedListID == list.id
                ) { selectedListID = list.id }
                .contextMenu {
                    Button("Edit") { vs.editingList = list }
                    Divider()
                    Button("Delete", role: .destructive) {
                        if selectedListID == list.id { selectedListID = nil }
                        store.delete(list)
                    }
                }
            }

            Divider().padding(.vertical, 2)

            Button {
                vs.newListName = ""
                vs.newListColorHex = nil
                vs.showingAddList = true
            } label: {
                Label("New List", systemImage: "plus")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $vs.showingAddList) {
            ListEditSheet(
                name: $vs.newListName,
                colorHex: $vs.newListColorHex,
                title: "New List"
            ) {
                store.add(TodoList(name: vs.newListName, colorHex: vs.newListColorHex))
            }
        }
        .sheet(item: $vs.editingList) { list in
            ListEditSheetCopy(list: list) { updated in
                store.update(updated)
            }
        }
    }

    private func listRow(
        label: String,
        systemIcon: String,
        colorHex: String?,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let hex = colorHex, let color = Color(hex: hex) {
                    Circle().fill(color).frame(width: 8, height: 8)
                } else {
                    Image(systemName: systemIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .frame(width: 8)
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
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : .primary)
    }
}

// MARK: - New list sheet

struct ListEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var colorHex: String?
    var title: String
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            TextField("List name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }
            PalettePickerView(selectedHex: $colorHex)
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
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
        dismiss()
    }
}

// MARK: - Edit existing list sheet

struct ListEditSheetCopy: View {
    @Environment(\.dismiss) private var dismiss

    final class ViewState: ObservableObject {
        @Published var draft: TodoList
        init(list: TodoList) { draft = list }
    }
    @StateObject private var vs: ViewState

    var onSave: (TodoList) -> Void

    init(list: TodoList, onSave: @escaping (TodoList) -> Void) {
        _vs = StateObject(wrappedValue: ViewState(list: list))
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit List").font(.headline)
            TextField("List name", text: $vs.draft.name)
                .textFieldStyle(.roundedBorder)
            PalettePickerView(selectedHex: $vs.draft.colorHex)
            HStack {
                Spacer()
                Button("Done") {
                    onSave(vs.draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
