import SwiftUI

struct TodoRowView: View {
    @EnvironmentObject private var store: TodoStore
    let item: TodoItem
    var onTap: (() -> Void)?
    /// Supplied by the "View Cleared" list so a cleared row can be un-cleared.
    var onRestore: (() -> Void)?

    private var itemTags: [Tag] { store.tags(for: item) }

    /// Shared accent for the in-progress checkbox glyph and the built-in "WIP" tag,
    /// so the two read as one consistent signal. Matches `AppPalette`'s Orange.
    private static let inProgressColor = Color(hex: "#FF9F0A") ?? .orange

    private var checkboxIcon: String {
        switch item.status {
        case .todo: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        }
    }

    private var checkboxColor: Color {
        switch item.status {
        case .todo: return .secondary
        case .inProgress: return Self.inProgressColor
        case .completed: return .accentColor
        }
    }

    private var dueDateColor: Color {
        if item.isOverdue { return .red }
        if item.isDueToday { return .orange }
        return .secondary
    }

    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Built-in indicator shown automatically on in-progress items — styled like
    /// `TagBadgeView` but not a real `Tag`; purely a view-level decoration driven by
    /// `item.status`.
    private var wipBadge: some View {
        Text("WIP")
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Self.inProgressColor.opacity(0.15)))
            .foregroundStyle(Self.inProgressColor.opacity(0.9))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Checkbox — tapping cycles todo -> in progress -> completed -> todo.
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                    store.cycleStatus(item)
                }
            } label: {
                Image(systemName: checkboxIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(checkboxColor)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: item.status)
            }
            .buttonStyle(.plain)
            .help("Todo \u{2192} In Progress \u{2192} Complete")

            // Title + meta
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .font(.system(size: 13))
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                // Meta row — always rendered (never inserted/removed) so the WIP
                // badge appearing/disappearing animates as a smooth height reveal
                // via `frame(maxHeight:)` + `clipped()`, instead of SwiftUI's
                // abrupt default insertion transition for conditional views.
                let showMeta = item.isInProgress || !itemTags.isEmpty || item.dueDate != nil
                HStack(spacing: 4) {
                    if item.isInProgress {
                        wipBadge
                            .transition(.scale(scale: 0.5, anchor: .leading).combined(with: .opacity))
                    }
                    ForEach(itemTags.sorted(by: { $0.name < $1.name })) { tag in
                        TagBadgeView(tag: tag)
                    }
                    if let due = item.dueDate {
                        HStack(spacing: 3) {
                            Image(systemName: item.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                                .font(.system(size: 9))
                            Text(Self.dueDateFormatter.string(from: due))
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(dueDateColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(dueDateColor.opacity(0.1)))
                    }
                }
                .padding(.top, showMeta ? 3 : 0)
                .frame(maxHeight: showMeta ? 300 : 0, alignment: .leading)
                .clipped()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Hover actions
            HoverActions {
                HStack(spacing: 2) {
                    Button {
                        store.toggleArchived(item)
                    } label: {
                        Image(systemName: item.isArchived ? "tray.and.arrow.up" : "archivebox")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help(item.isArchived ? "Restore" : "Archive")

                    Button { withAnimation(.spring(duration: 0.3)) { onTap?() } } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Edit")
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .overlay(alignment: .leading) {
            // Left color accent bar — an overlay (not an HStack child) so it adds
            // zero width/height to the row; rows with and without a color stay
            // the exact same size.
            if let hex = item.colorHex, let color = Color(hex: hex) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3)
                    .padding(.vertical, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(duration: 0.3)) { onTap?() } }
        .contextMenu {
            if item.isCleared {
                Button("Restore") { onRestore?() }
                Divider()
                Button("Delete Permanently", role: .destructive) {
                    store.delete(item)
                }
            } else {
                if item.status != .todo {
                    Button("Mark Todo") {
                        withAnimation(.spring(duration: 0.2)) { store.setStatus(.todo, on: item) }
                    }
                }
                if item.status != .inProgress {
                    Button("Mark In Progress") {
                        withAnimation(.spring(duration: 0.2)) { store.setStatus(.inProgress, on: item) }
                    }
                }
                if item.status != .completed {
                    Button("Mark Complete") {
                        withAnimation(.spring(duration: 0.2)) { store.setStatus(.completed, on: item) }
                    }
                }
                Divider()
                Button(item.isArchived ? "Restore from Archive" : "Archive") {
                    store.toggleArchived(item)
                }
                Divider()
                Button("Delete", role: .destructive) {
                    store.delete(item)
                }
            }
        }
        .task(id: item.status) {
            // Delayed auto-clear: once a todo is marked complete, wait briefly (so
            // the completed state is visible) then move it into the hidden Cleared
            // bucket. Re-checking complete and marking it incomplete again before
            // the delay elapses cancels this task (the `id` changes) with no effect.
            guard item.isCompleted else { return }
            let delay = UInt64(max(0, store.settings.autoClearDelaySeconds))
            do {
                try await Task.sleep(nanoseconds: delay * 1_000_000_000)
            } catch {
                return
            }
            guard let current = store.items.first(where: { $0.id == item.id }),
                  current.isCompleted, !current.isCleared, !current.isArchived
            else { return }
            store.clearItem(current)
        }
    }
}

// MARK: - Hover helper

struct HoverActions<Content: View>: View {
    final class ViewState: ObservableObject {
        @Published var isHovered = false
    }

    @StateObject private var vs = ViewState()
    let content: () -> Content

    var body: some View {
        content()
            .opacity(vs.isHovered ? 1 : 0)
            .onHover { vs.isHovered = $0 }
    }
}
