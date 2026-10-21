import SwiftUI

struct ListSidebarView: View {
    final class ViewState: ObservableObject {
        /// Toggled by the bottom-toolbar reorder button; shows a leading grip handle
        /// on each list row (the drag gesture itself is always available).
        @Published var isEditing = false
        /// The list currently being dragged over; drives the drop-insertion
        /// indicator shown above that row.
        @Published var dragOverListID: UUID?
    }

    @EnvironmentObject private var store: TodoStore
    @StateObject private var vs = ViewState()
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
        vs.dragOverListID = nil
        return true
    }

    /// Updates `vs.dragOverListID` from a row's `isTargeted` callback, ignoring a
    /// stale `false` for a different row than the one currently highlighted (can
    /// arrive after the next row's `true`, depending on drag timing).
    private func setDragTarget(_ id: UUID, isTargeted: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            vs.dragOverListID = isTargeted ? id : (vs.dragOverListID == id ? nil : vs.dragOverListID)
        }
    }

    /// A thin accent-colored bar shown directly above a row while something is
    /// being dragged over it, indicating where the dropped item will land.
    private var dropIndicator: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(height: 2)
            .padding(.horizontal, 8)
            .transition(.opacity)
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
                    if vs.dragOverListID == list.id {
                        dropIndicator
                    }
                    listRow(
                        label: list.name,
                        systemIcon: "list.bullet",
                        colorHex: list.colorHex,
                        emoji: list.emoji,
                        count: store.activeCount(in: list),
                        isSelected: selectedListID == list.id,
                        showGripHandle: true
                    ) { selectedListID = list.id }
                    .contextMenu {
                        Button("Edit") { withAnimation(.spring(duration: 0.3)) { editingList = list } }
                        Divider()
                        Button("Delete", role: .destructive) {
                            withAnimation(.spring(duration: 0.3)) { confirmingDeleteList = list }
                        }
                    }
                    .draggable(list.id.uuidString)
                    .dropDestination(for: String.self) { droppedIDs, _ in
                        handleListDrop(droppedIDs, onto: list)
                    } isTargeted: { targeted in
                        setDragTarget(list.id, isTargeted: targeted)
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

                reorderButton

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

    /// Toggles `vs.isEditing`, showing a leading grip handle on each list row as a
    /// discoverable affordance for the always-available drag-to-reorder gesture.
    private var reorderButton: some View {
        Button {
            withAnimation(.spring(duration: 0.2)) { vs.isEditing.toggle() }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .foregroundStyle(vs.isEditing ? Color.accentColor : .secondary)
        .help(vs.isEditing ? "Done Reordering" : "Reorder Lists")
    }

    // swiftlint:disable:next function_parameter_count
    private func listRow(
        label: String,
        systemIcon: String,
        colorHex: String?,
        emoji: String?,
        count: Int,
        isSelected: Bool,
        showGripHandle: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        // Not a `Button`: on macOS a Button's gesture recognizer claims mouse-down
        // before the call site's `.draggable()` can start a drag, breaking reorder.
        HStack(spacing: 6) {
            if showGripHandle && vs.isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
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
        .foregroundStyle(isSelected ? .white : .primary)
        .simultaneousGesture(TapGesture().onEnded(action))
    }
}
