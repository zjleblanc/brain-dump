import SwiftUI

@main
struct TodosApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra {
            MainContentView()
                .environmentObject(store)
        } label: {
            MenuBarLabel()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Shows a checklist icon in the menu bar with a count of active items.
private struct MenuBarLabel: View {
    @EnvironmentObject private var store: TodoStore

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "checklist")
            if store.activeItemCount > 0 {
                Text("\(store.activeItemCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
    }
}
