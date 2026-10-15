# Changelog

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
