import SwiftUI

@main
struct TodosApp: App {
    @StateObject private var store = TodoStore()

    init() {
        // Prewarm the emoji scan (~150ms) on a background queue so it's already
        // cached by the time a user opens the list emoji picker, avoiding a
        // one-time stutter during the sheet's slide-up animation.
        DispatchQueue.global(qos: .utility).async {
            _ = AppEmojiPalette.emojis
        }
    }

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
