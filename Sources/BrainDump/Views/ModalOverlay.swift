import SwiftUI

/// Renders modal-dialog-style content as an in-panel SwiftUI overlay rather than a real
/// AppKit sheet. `.sheet()` is unreliable inside `MenuBarExtra(.menuBarExtraStyle: .window)`
/// because its backing panel is a non-activating NSPanel that can't properly host a true
/// sheet window — the sheet's window gets torn down almost immediately after it appears,
/// before the user can interact with it, which can also cause the whole popover to lose key
/// and close. This overlay stays within the same panel, so it has no such window-lifecycle
/// issues.
struct ModalOverlayContainer<Content: View>: View {
    /// Called when Escape is pressed, mirroring the native AppKit convention where
    /// Escape cancels a presented sheet. Pass nil to disable (e.g. when the content
    /// has no safe default dismiss action).
    var onEscape: (() -> Void)?
    @ViewBuilder var content: Content

    init(onEscape: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onEscape = onEscape
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .onExitCommand { onEscape?() }
    }
}

// MARK: - Bottom sheet container

/// Slides content up from the bottom edge of the panel — no popover, no centred modal.
/// Use this everywhere instead of ModalOverlayContainer.
struct BottomSheetContainer<Content: View>: View {
    var onEscape: (() -> Void)?
    @ViewBuilder var content: Content

    init(onEscape: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onEscape = onEscape
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { onEscape?() }

            content
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 14
                ))
                .shadow(color: .black.opacity(0.18), radius: 20, y: -4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .onExitCommand { onEscape?() }
    }
}
