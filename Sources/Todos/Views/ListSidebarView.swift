import SwiftUI

struct ListSidebarView: View {
    @EnvironmentObject private var store: TodoStore
    @Binding var selectedListID: UUID?
    @Binding var showingAddList: Bool
    @Binding var editingList: TodoList?
    @Binding var newListName: String
    @Binding var newListColorHex: String?

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
                    Button("Edit") { withAnimation(.spring(duration: 0.3)) { editingList = list } }
                    Divider()
                    Button("Delete", role: .destructive) {
                        if selectedListID == list.id { selectedListID = nil }
                        store.delete(list)
                    }
                }
            }

            Divider().padding(.vertical, 2)

            Button {
                newListName = ""
                newListColorHex = nil
                withAnimation(.spring(duration: 0.3)) { showingAddList = true }
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
    }

    // swiftlint:disable:next function_parameter_count
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
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : .primary)
    }
}

// MARK: - New list sheet

struct ListEditSheet: View {
    @Binding var name: String
    @Binding var colorHex: String?
    var title: String
    var onSave: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            TextField("List name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }
            PalettePickerView(selectedHex: $colorHex)
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
            PalettePickerView(selectedHex: $vs.draft.colorHex)
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
