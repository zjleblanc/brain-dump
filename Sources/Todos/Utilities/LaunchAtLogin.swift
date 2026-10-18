import ServiceManagement

/// Thin wrapper around `SMAppService.mainApp`, the modern (macOS 13+) API for
/// registering/unregistering this app as a login item. No helper app or
/// `LSSharedFileList` is needed — the OS is the source of truth for the toggle
/// state, so no value is persisted in `AppSettings`.
enum LaunchAtLogin {
    /// `SMAppService` only works when running from a properly bundled `.app`
    /// (i.e. it has a real bundle identifier). During development via `swift run`
    /// there is no bundle identifier, so the feature is unavailable.
    static var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters the app as a login item.
    static func setEnabled(_ enabled: Bool) throws {
        guard isAvailable else { return }
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
