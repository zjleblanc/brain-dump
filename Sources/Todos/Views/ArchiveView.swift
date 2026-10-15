import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject private var store: TodoStore

    final class ViewState: ObservableObject {
        @Published var searchText = ""
        @Published var selectedItem: TodoItem?
    }

    @StateObject private var vs = ViewState()

    private var archivedItems: [TodoItem] {
        store.items
            .filter { $0.isArchived }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var filtered: [TodoItem] {
        guard !vs.searchText.isEmpty else { return archivedItems }
        let query = vs.searchText.lowercased()
        return archivedItems.filter {
            $0.title.lowercased().contains(query) ||
            $0.notes.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Archive").font(.headline)
                Spacer()
                if !archivedItems.isEmpty {
                    Button("Clear All", role: .destructive) {
                        store.clearArchive()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if archivedItems.isEmpty {
                emptyState
            } else {
                SearchField(text: $vs.searchText, placeholder: "Search archive…")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { item in
                            TodoRowView(item: item) { vs.selectedItem = item }
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .sheet(item: $vs.selectedItem) { item in
            TodoDetailView(item: item) { updated in
                store.update(updated)
            }
            .environmentObject(store)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "archivebox")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No Archived Items").font(.headline).foregroundStyle(.secondary)
            Text("Archived todos appear here.").font(.caption).foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
