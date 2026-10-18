# BrainDump — AGENTS.md

macOS menubar todo list app. Native SwiftUI + JSON persistence, built with Swift Package Manager.
No Xcode.app required — builds and runs with `swift run`.

## Requirements

- macOS 15+
- Swift 6+ (Command Line Tools): `xcode-select --install`

## Project Layout

```
braindump/
├── Package.swift                    # SPM manifest (swift-tools-version: 6.0, macOS 15, zero deps)
├── Sources/BrainDump/
│   ├── BrainDumpApp.swift           # @main — MenuBarExtra + @StateObject TodoStore
│   ├── Models/
│   │   ├── TodoStore.swift          # ObservableObject; JSON persistence at ~/Library/Application Support/BrainDump/data.json
│   │   ├── TodoItem.swift           # Codable struct: title, notes, isCompleted, isArchived, dueDate, colorHex, tagIDs, listID
│   │   ├── TodoList.swift           # Codable struct: name, colorHex, sortOrder
│   │   └── Tag.swift                # Codable struct: name, colorHex
│   ├── Views/
│   │   ├── MainContentView.swift    # Root popover (toolbar, sidebar, list, quick-add) + TodoListPane
│   │   ├── TodoRowView.swift        # Checkbox, color bar, tags, due date, hover actions
│   │   ├── TodoDetailView.swift     # Edit sheet (title, notes, list, color, due, tags)
│   │   ├── ListSidebarView.swift    # Category/list picker + create/edit/delete sheets
│   │   ├── ArchiveView.swift        # Archived items viewer
│   │   ├── TagBadgeView.swift       # Colored pill badge
│   │   └── SearchField.swift        # Search text field
│   └── Utilities/
│       └── ColorHex.swift           # Color↔hex conversion, AppPalette, PalettePickerView
├── scripts/
│   └── bundle.sh                    # Build + package as BrainDump.app (version via VERSION env var)
├── .github/workflows/
│   └── release.yml                  # Tag-triggered build, package, codesign/notarize, publish
├── docs/
│   └── RELEASING.md                 # Versioning policy + release process
├── CHANGELOG.md                     # Keep a Changelog-style, versioned per release
└── AGENTS.md                        # This file
```

## Build & Run

```bash
# Run in development (builds debug binary and launches the menubar app)
swift run

# Build only
swift build

# Release build
swift build -c release
```

After `swift run`, a checklist icon appears in the macOS menu bar. Click it to open the popover.

## Package as .app

```bash
# Debug .app (fast, for local testing)
./scripts/bundle.sh

# Release .app (optimised, for distribution)
./scripts/bundle.sh release

# Release + codesign
./scripts/bundle.sh release sign "Developer ID Application: Your Name (TEAMID)"

# Open the resulting app
open BrainDump.app
```

## Distribution

1. Build release + codesign (requires Apple Developer account)
2. Notarise with `xcrun notarytool`
3. Package as DMG with `create-dmg` (`brew install create-dmg`)

Or distribute via Homebrew Cask — add `BrainDump.app.zip` to a tap and write a Cask formula.

## Releasing

Releases are tag-driven via [.github/workflows/release.yml](.github/workflows/release.yml):
pushing a `vX.Y.Z` tag triggers a macOS runner that builds, bundles,
optionally codesigns/notarizes, packages a `.zip`/`.dmg`, and publishes a
GitHub Release with notes pulled from [CHANGELOG.md](CHANGELOG.md).

The version is never hard-coded — `scripts/bundle.sh` reads it from the
`VERSION` env var (set by CI from the tag) and injects it into
`Info.plist`. Local dev builds default to `0.0.0-dev`.

See [docs/RELEASING.md](docs/RELEASING.md) for the full process, versioning
policy, and codesigning/notarization secret setup.

## Data Storage

All data is saved as JSON at:
```
~/Library/Application Support/BrainDump/data.json
```

The file is written atomically after every mutation. No database engine, no migration setup.

## Architecture Notes

### Key design decisions

- **MenuBarExtra(.window)** — rich SwiftUI popover, not a plain menu
- **LSUIElement = true** in `Info.plist` (bundle.sh) — hides the Dock icon
- **ObservableObject + @Published** for `TodoStore` — works with Swift Command Line Tools (Swift 6.4 macros like `@State` and `@Observable` require the full Xcode.app toolchain due to missing `SwiftUIMacros`/`SwiftDataMacros` plugins in CLT)
- **@StateObject + nested ObservableObject** for per-view local state — replaces `@State` throughout
- **Codable structs** for data models — simpler than SwiftData, no macro plugins needed
- **JSON file** for persistence — zero dependencies, easy to inspect/backup
- **Soft-delete archive** — `isArchived = true` keeps items retrievable; hard delete available from archive view
- **Colors as hex strings** (`#RRGGBB`) — stored in model, rendered via `ColorHex.swift`
- **Tag–Item relationship** via `tagIDs: [UUID]` on `TodoItem` (join by value, not by reference)

### State flow

```
TodoStore (ObservableObject)
    ↓ @EnvironmentObject
MenuBarLabel  MainContentView  ListSidebarView  TodoRowView  ...
    ↓ store.update(item)
TodoStore.save() → data.json
```

## Conventions

- Conventional commits: `feat`, `fix`, `chore`, `refactor`, `docs`
- All UI in `Sources/BrainDump/Views/`, all data models in `Sources/BrainDump/Models/`
- Utilities (no SwiftUI scene logic) live in `Sources/BrainDump/Utilities/`
- Per-view local mutable state lives in a nested `final class ViewState: ObservableObject` inside the `View` struct, accessed via `@StateObject private var vs = ViewState()`
