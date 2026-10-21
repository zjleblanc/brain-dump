# Changelog

## [1.4.4]

### Changed
- Removed "In Progress" section header; in-progress items now interleave with todos in the main list, distinguished by their half-filled checkbox style and WIP badge
- Unified reorder-mode experience for lists and tasks, with a shared toggle button and visual grip handles
- Task reorder button moved to the status filter bar and hidden when reordering isn't supported (e.g. searching or viewing "All")
- Task color bar indicator moved to the right edge of the row for a cleaner leading edge

### Fixed
- Fixed drag-to-reorder on macOS by swapping exclusive tap gestures for simultaneous ones, resolving a conflict where the button/row would capture clicks before a drag could start
- Added a visual drop indicator (a horizontal bar) during reordering to show exactly where an item will land

### Refactored
- Extracted list-edit and deletion dialogs from `ListSidebarView.swift` to a new `ListEditSheets.swift` file
- Restructured `MainContentView.swift` into extensions to comply with file-length and type-body-length lint rules

## [1.4.3]

### Added
- App version and "View Source" link (pointing to GitHub) in the `SettingsView` header

### Changed
- Task color accent bar (`TodoRowView`) now renders as a leading-edge `.overlay` on the row instead of an `HStack` child, so it no longer forces a taller minimum height or shifts content right by its width — rows with and without a color are now the exact same size
- Replaced the binary "View Completed" footer toggle with a multi-select status filter: `MainContentView.ViewState.statusFilter: Set<TodoStatus>` (defaulting to Todo + In Progress) backs three pill buttons — Todo / In Progress / Completed — that each toggle membership, with at least one status always kept selected so the list can't be filtered to nothing. `TodoListPane` now takes `statusFilter` instead of `showCompleted` and groups matching items into Todo (unlabeled, as before) / In Progress / Completed sections, each with its own header except Todo; drag-to-reorder is now also gated on both Todo and In Progress being selected, since `TodoStore.moveItem` always reindexes against the full non-completed group regardless of which statuses are currently shown

### Fixed
- `TodoRowView` checkbox-to-in-progress animation was clunky on bare todos (no tags, no due date): the meta row holding the WIP badge was conditionally inserted/removed, so the row's height snapped taller the instant the badge appeared. The meta row is now always rendered and its reveal/collapse is driven by an animated `frame(maxHeight:)` + `clipped()` instead of view insertion, with the WIP badge itself getting a scale/opacity `.transition()`; the checkbox's `withAnimation` spring was also widened from `duration: 0.2` to `duration: 0.35, bounce: 0.15` to give the height change room to read as smooth rather than abrupt

## [1.4.2]

### Added
- Three-state todo lifecycle — `TodoStatus` (`Sources/BrainDump/Models/TodoItem.swift`) replaces the plain `isCompleted: Bool` with `todo` / `inProgress` / `completed`; `isCompleted`/`isInProgress` remain as computed properties, and legacy `isCompleted` JSON decodes straight into `status` so existing `data.json` files load unchanged
- In-progress indicator — the row checkbox (`TodoRowView`) shows a half-filled orange circle for in-progress items (vs. an open circle for todo, filled checkmark for completed); tapping the checkbox now cycles todo → in progress → completed → todo (`TodoStore.cycleStatus(_:)`), and the context menu gained explicit "Mark Todo" / "Mark In Progress" / "Mark Complete" actions (`TodoStore.setStatus(_:on:)`)
- Built-in "WIP" badge — automatically shown next to tags on in-progress rows; purely a view-level decoration driven by status, not a real `Tag`
- Drag-to-reorder for lists in the sidebar (`ListSidebarView`), wired up to the previously-unused `TodoStore.moveList(from:to:)`
- Drag-to-reorder for tasks within a specific list — new `TodoItem.sortOrder` field plus `TodoStore.moveItem(from:to:inList:)`; active rows in a selected list sort by `sortOrder` and support drag-and-drop, while the "All" view (and active searches) keep the existing recency sort with reordering disabled, since row order can't be mapped back to a single list's sort positions

### Changed
- `TodoListPane` extracted from `MainContentView.swift` into its own file (`Sources/BrainDump/Views/TodoListPane.swift`) to keep file length within the project's SwiftLint limit
- `TodoStore.load()` now also backfills `sortOrder` for items persisted before manual reordering existed, grouped per list and ordered by `createdAt`

## [1.4.1]

### Fixed
- `Sources/BrainDump/BrainDumpApp.swift` — release builds failed in CI with `static property 'templateImage' is not concurrency-safe because non-'Sendable' type 'NSImage' may have shared mutable state` under Swift 6's strict concurrency checking; marked `BrainIcon.templateImage` `@MainActor`, since it's only ever read from `MenuBarLabel.body` (itself `@MainActor`-isolated)
- `scripts/bundle.sh` — downloaded `.dmg`/`.zip` releases showed macOS's "is damaged and can't be opened" error instead of the normal "unidentified developer" prompt. `swift build` leaves the raw executable with a bare ad-hoc, linker-applied signature covering only the Mach-O itself; once `bundle.sh` wrapped it in `Info.plist`/`Resources` to form the `.app`, that stale signature's `CodeDirectory` still claimed sealed resources must be present but no `_CodeSignature/CodeResources` seal existed for the assembled bundle, which Gatekeeper treats as invalid once the file is quarantined. The fully assembled bundle is now always re-signed — ad-hoc (`--sign -`) when no Developer ID is configured, or with the real identity otherwise

## [1.4.0]

### Added
- Custom app icon (`Sources/BrainDump/Resources/AppIcon.icns`), generated without requiring an Apple Developer account — `scripts/bundle.sh` copies it into the packaged `.app` and sets `CFBundleIconFile`; `Package.swift` excludes it from SPM's default resource-copying
- Menu bar glyph — `MenuBarLabel` now shows a monochrome, square, line-art brain icon (extracted directly from the app icon's artwork and baked into a template `NSImage`) in place of the generic `checklist` SF Symbol
- App icon shown in `SettingsView` (new "About" header) and in `README.md`, via a PNG (`Sources/BrainDump/Resources/AppIcon.png`) extracted from `AppIcon.icns` for Markdown rendering

### Changed
- **Rebranded the app from "Todos" to "BrainDump"**: `Package.swift` package/target renamed; `Sources/Todos/` moved to `Sources/BrainDump/`; `TodosApp.swift` renamed to `BrainDumpApp.swift` (`struct TodosApp` → `struct BrainDumpApp`); bundle identifier changed from `com.todos.app` to `com.braindump.app`; data directory moved from `~/Library/Application Support/Todos/` to `~/Library/Application Support/BrainDump/` (no migration — existing `data.json` is not carried over); updated `scripts/bundle.sh`, `.github/workflows/release.yml`, `Makefile`, `.vscode/launch.json`, `.gitleaks.toml`, `AGENTS.md`, `docs/RELEASING.md`, and `README.md` accordingly

### Fixed
- `.github/workflows/release.yml` — the `.dmg` artifact was never submitted for notarization (only the `.zip` was), causing macOS Gatekeeper to reject the DMG download as "damaged"; added a `Notarize .dmg` step that submits the DMG to `notarytool` and staples the ticket after packaging

## [1.3.1]

### Fixed
- `.github/workflows/release.yml` — the optional-codesigning `if:` condition referenced `secrets.MACOS_CERTIFICATE_P12_BASE64` directly, which GitHub Actions rejects with `Unrecognized named-value: 'secrets'` (secrets can't be used directly inside `if:` conditionals); now surfaced via a job-level `HAS_SIGNING_CERT` env var and checked as `env.HAS_SIGNING_CERT == 'true'` instead

## [1.3.0] - 2026-10-16 — Full emoji/color pickers, toolbar rework, and unified completed-items toggle

### Added
- `AddTodoSheet` — added a Tags section (with inline tag creation, same `FlowLayout` picker as `TodoDetailView`) and reorganized into a two-column layout (Title/Notes on the left; List/Tags/Due Date/Color on the right), matching `TodoDetailView`
- `EmojiPicker.swift` (new) — `AppEmojiPalette.emojis` computed from Unicode scalar properties (`isEmojiPresentation`), giving ~1,200+ emoji in a scrollable in-app grid; replaces the "pick an emoji" button that called `NSApp.orderFrontCharacterPalette`
- `SpectrumColorPicker.swift` (new) — fully custom SwiftUI `SpectrumColorPickerView` (draggable saturation/brightness field, hue strip, hex text entry, quick presets) for continuous color choice without opening `NSColorPanel`; replaces `PalettePickerView` everywhere a color is picked (todo color, list color, tag color)
- `Color.toHex()`, `Color.hsb()`, and `HSBComponents` (`ColorHex.swift`) — RGB↔HSB/hex conversions backing the new color picker
- `TodosApp` prewarms the emoji scan on a background queue at launch so the ~150ms Unicode scan is already cached before the list emoji picker is first opened

### Changed
- Toolbar: Quit (power icon) moved to the far left, Settings (gear icon) stays far right, and the active list name/icon is now centered via a `ZStack`, independent of the button widths on either side
- Main pane search row simplified to just the search field and a `+` add-todo button; the old full-width "Add a todo…" quick-add bar was removed
- Completed/cleared items unified into one toggle: open (active) tasks are now always visible; a "View Completed"/"Hide Completed" footer bar (eye icon + text, right-aligned) shows or hides a single Completed section containing both freshly-completed and already auto-cleared items, instead of swapping the whole pane to a separate cleared-only view
- `ListIconPickerView` now uses `EmojiPickerView` and `SpectrumColorPickerView` instead of a raw text field plus the system character-palette button

### Fixed
- Emoji selection for lists was completely broken: the "pick an emoji" button opened the system Character Viewer, which caused the entire `MenuBarExtra(.window)` popover to lose key status and dismiss before a selection could be made

## [1.2.0] - 2026-10-16 — Two-column todo editor, auto-clearing completed items, and list emoji icons

### Added
- `TodoDetailView` — redesigned into a two-column layout (Title/Notes on the left, List/Due Date/Color/Tags on the right, widened to 520 pt) with a sticky bottom footer holding `Delete Todo` and `Done`; the top header now only shows the title
- Completed-item auto-clear workflow: the checkbox gives a brief bounce/pulse indicator on completion, then a background task (`TodoRowView`) auto-clears the item into a new hidden "Cleared" state after a configurable delay — no more manual "Clear" button/notification bar
- "View Cleared" toggle (eye icon next to search in `MainContentView`) shows auto-cleared items in their own list, scoped to the current list/search; each row supports **Restore** or **Delete Permanently** via context menu
- `SettingsView.swift` (new) — settings sheet, opened via a new gear icon in the main toolbar, with pickers for: auto-clear delay (1/2/3/5/10/15/30 seconds, default 3s), cleared-item retention (Never/1/7/30/90 days, default 30), and archived-item retention (Never/1/7/30/90 days, default Never)
- `AppSettings.swift` (new) — persisted app-wide settings model with a hand-written `Codable` implementation so new fields never break decoding of older `data.json` files
- `TodoStore.purgeExpired()` — permanently deletes cleared/archived items past their configured retention window; runs on launch and hourly via an internal timer
- List emoji icons — `TodoList.emoji` plus a `ListIconPickerView` (emoji text field + button that opens macOS's native Character Viewer) in both list-edit sheets; emoji takes precedence over the color dot wherever a list's icon is shown (sidebar rows, main toolbar title)
- `ListSidebarView` sticky icon-only footer (`+` New List, archive-box View Archive) pinned via `safeAreaInset`, replacing the old inline "New List" row and the toolbar's archive button

### Changed
- `ListSidebarView` list rows gained `.contentShape(Rectangle())` so the entire row is clickable, not just the icon/text
- `TodoListPane` dividers between rows now span the full row width (removed the `.padding(.leading, 40)` gap)
- `TodoItem` gained optional `clearedAt`/`archivedAt` timestamps (`isCleared` is now computed from `clearedAt`); `toggleArchived` stamps `archivedAt` and clears any `clearedAt`
- `TodoStore` is now `@MainActor`; legacy archived items without `archivedAt` are backfilled on load so a newly-enabled retention policy doesn't immediately purge pre-existing data
- Removed `TodoStore.deleteCompleted(in:)` and the "Completed · Clear" notification-bar button it powered

## [1.1.0] - 2026-10-16 — Slide-up panels, improved add-todo flow, and row layout fixes

### Added
- `ModalOverlay.swift` — new `BottomSheetContainer` that anchors content at the bottom of the panel, slides in from below with a spring transition, and rounds only the top corners; tap the backdrop to dismiss
- `AddTodoSheet` (in `MainContentView.swift`) — full creation form (title, notes, list, due date, color) that auto-focuses the title field; replaces the old type-title-then-open-edit-modal flow

### Changed
- Quick-add bar replaced with a single tappable row that opens `AddTodoSheet` via a bottom-sheet slide; removed the inline `TextField`
- All modal overlays in `MainContentView`, `TodoDetailView`, and `ArchiveView` converted from `ModalOverlayContainer` (centred popover) to `BottomSheetContainer`; state mutations wrapped in `withAnimation(.spring(duration: 0.3))`
- `TodoDetailView`, `ListEditSheet`, `ListEditSheetCopy`, and `TagEditSheet` now accept explicit `onDismiss` closures instead of relying on `@Environment(\.dismiss)`, enabling the new overlay model
- `ListSidebarView` sheet state lifted to `MainContentView` so all overlay logic lives in one place
- `TodoRowView` — `HStack` alignment changed from `.top` to `.center`; removed top-padding nudges on checkbox and color bar; title `VStack` given `.frame(maxWidth: .infinity)` so text fills available width; padding increased to 12 pt horizontal, 6 pt vertical
- `ListSidebarView` icon/circle container — both the colored dot and the fallback system icon now sit in a fixed `16×16` frame for consistent vertical alignment with the label

### Fixed
- Checkbox circle was top-anchored instead of vertically centered in each row
- Todo title text was not expanding to fill the right side of the row
- Sidebar list icons and color dots were misaligned relative to label text

## [1.0.0] - 2026-10-15 — Initial implementation of macOS menubar todo app

### Added
- `Package.swift` — Swift Package Manager manifest targeting macOS 15+, zero external dependencies
- `TodosApp.swift` — `@main` app entry point using `MenuBarExtra(.window)` with live badge count showing active item total
- **Data models** (`Sources/Todos/Models/`)
  - `TodoItem` — Codable struct with title, notes, completion, archive, optional due date, optional color, list assignment, and tag references
  - `TodoList` — Codable struct for named, color-coded categories with sort order
  - `Tag` — Codable struct for named, color-coded badges
  - `TodoStore` — `ObservableObject` managing all state; persists atomically as JSON at `~/Library/Application Support/Todos/data.json`
- **Views** (`Sources/Todos/Views/`)
  - `MainContentView` — root popover with toolbar, list sidebar, filtered todo pane, search field, and quick-add bar
  - `TodoListPane` — live-filtered list with active and completed sections; "Clear" button for completed items
  - `TodoRowView` — checkbox, left color accent bar, tag badges, relative due date with overdue/today indicators, hover-reveal archive and edit actions, context menu
  - `TodoDetailView` — edit sheet for title, notes, list assignment, optional due date (graphical picker), color palette, and tag selection; inline tag creation
  - `ListSidebarView` — category picker with active item counts; create, rename, colorize, and delete lists
  - `ArchiveView` — searchable archive with per-item restore and bulk clear
  - `TagBadgeView` — colored pill badge
  - `SearchField` — search field with clear button
- **Utilities** (`Sources/Todos/Utilities/`)
  - `ColorHex.swift` — `Color ↔ hex string` conversion, 10-color `AppPalette`, `PalettePickerView` swatch grid
- `scripts/bundle.sh` — packages the SPM binary into a `Todos.app` bundle with correct `Info.plist` (`LSUIElement = true`); supports debug, release, and optional codesigning
- `AGENTS.md` — build, run, and architecture documentation

### Notes
- Swift 6.4 Command Line Tools ship without `SwiftUIMacros.dylib`, so `@State` (now a macro in the macOS 27 SDK) is unavailable. Local view state uses nested `final class ViewState: ObservableObject` + `@StateObject` throughout. All other SwiftUI primitives (`@StateObject`, `@EnvironmentObject`, `@Published`, `@Binding`, `@FocusState`, `@Environment`) work correctly.
- SwiftData was evaluated and ruled out for the same reason (`SwiftDataMacros` plugin absent from CLT); JSON persistence was chosen instead.
