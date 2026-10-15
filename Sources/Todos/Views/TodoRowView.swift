import SwiftUI

struct TodoRowView: View {
    @EnvironmentObject private var store: TodoStore
    let item: TodoItem
    var onTap: (() -> Void)?

    private var itemTags: [Tag] { store.tags(for: item) }

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

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Left color accent bar
            if let hex = item.colorHex, let color = Color(hex: hex) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: 36)
                    .padding(.top, 2)
            }

            // Checkbox
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    store.toggleCompleted(item)
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isCompleted ? Color.accentColor : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            // Title + meta
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13))
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                if !itemTags.isEmpty || item.dueDate != nil {
                    HStack(spacing: 4) {
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
                }
            }

            Spacer()

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

                    Button { onTap?() } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Edit")
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .contextMenu {
            Button(item.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                store.toggleCompleted(item)
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
