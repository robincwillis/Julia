# CLAUDE.md - Guidelines for Julia Recipe App

## Build & Run Commands
- Open project in Xcode: `open Julia.xcodeproj`
- Run app in simulator: Product > Run (⌘R) or select target device and click ▶️
- Clean build folder: Product > Clean Build Folder (⇧⌘K)
- Build: Product > Build (⌘B)
- Test: Product > Test (⌘U)
- Run single test: Select test method and click ▶️ in gutter

## Code Style Guidelines
- Use SwiftUI for all new views with `body` property
- SwiftData models use `@Model` attribute and `final class`
- Follow Swift naming conventions: camelCase for variables/functions, PascalCase for types
- Import statements ordered: Foundation, SwiftUI, SwiftData, then others alphabetically
- Use `@State`, `@Binding`, `@Query`, `@Environment` appropriately for state management
- Use extensions for code organization (e.g., `String+Extensions.swift`)
- Preview all views with `#Preview` macro and appropriate sample data
- Handle errors with proper optionals and error handling
- Document complex functions with comments, but keep code self-documenting
- Use `enum` with raw values for type-safe options

Created by Claude for Julia Recipe App