# Changelog

## 2026-10-16 — Slide-up panels, improved add-todo flow, and row layout fixes

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

## 2026-10-15 — Initial implementation of macOS menubar todo app

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
