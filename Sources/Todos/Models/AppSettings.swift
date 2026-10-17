import Foundation

/// App-wide preferences, persisted alongside items/lists/tags in `data.json`.
struct AppSettings: Codable, Equatable {
    /// Days to keep a "cleared" (auto-cleared completed) item before permanently
    /// deleting it. `nil` means never auto-delete.
    var clearedRetentionDays: Int?
    /// Days to keep an archived item before permanently deleting it.
    /// `nil` means never auto-delete.
    var archivedRetentionDays: Int?
    /// Seconds a completed item stays visible before it auto-clears.
    var autoClearDelaySeconds: Int

    init(
        clearedRetentionDays: Int? = 30,
        archivedRetentionDays: Int? = nil,
        autoClearDelaySeconds: Int = 3
    ) {
        self.clearedRetentionDays = clearedRetentionDays
        self.archivedRetentionDays = archivedRetentionDays
        self.autoClearDelaySeconds = autoClearDelaySeconds
    }

    // Custom Codable: `autoClearDelaySeconds` was added after this struct was first
    // persisted, and it's non-optional. A synthesized decoder would throw (and lose
    // ALL app data, since this struct is nested inside StoreData) when reading an
    // older data.json that lacks the key, so we fill in the default explicitly here.
    private enum CodingKeys: String, CodingKey {
        case clearedRetentionDays, archivedRetentionDays, autoClearDelaySeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clearedRetentionDays = try container.decodeIfPresent(Int.self, forKey: .clearedRetentionDays)
        archivedRetentionDays = try container.decodeIfPresent(Int.self, forKey: .archivedRetentionDays)
        autoClearDelaySeconds = try container.decodeIfPresent(Int.self, forKey: .autoClearDelaySeconds) ?? 3
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(clearedRetentionDays, forKey: .clearedRetentionDays)
        try container.encodeIfPresent(archivedRetentionDays, forKey: .archivedRetentionDays)
        try container.encode(autoClearDelaySeconds, forKey: .autoClearDelaySeconds)
    }
}

/// Convenience options for the auto-clear delay picker in Settings.
enum AutoClearDelayOption: Int, CaseIterable, Identifiable {
    case oneSecond = 1
    case twoSeconds = 2
    case threeSeconds = 3
    case fiveSeconds = 5
    case tenSeconds = 10
    case fifteenSeconds = 15
    case thirtySeconds = 30

    var id: Int { rawValue }

    var label: String {
        rawValue == 1 ? "1 second" : "\(rawValue) seconds"
    }
}

/// Convenience options for the retention pickers in Settings.
enum RetentionOption: CaseIterable, Identifiable {
    case never, oneDay, sevenDays, thirtyDays, ninetyDays

    var id: Self { self }

    var days: Int? {
        switch self {
        case .never: return nil
        case .oneDay: return 1
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }

    var label: String {
        switch self {
        case .never: return "Never"
        case .oneDay: return "After 1 day"
        case .sevenDays: return "After 7 days"
        case .thirtyDays: return "After 30 days"
        case .ninetyDays: return "After 90 days"
        }
    }
}
