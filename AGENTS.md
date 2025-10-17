# GitWall - Agent Instructions

## Commands
- **Test**: `flutter test` (all tests), `flutter test test/widget_test.dart` (single test file)
- **Build**: `flutter build windows` (release), `flutter run` (debug)
- **Lint/Analyze**: `flutter analyze`
- **Format**: `dart format .`

## Architecture
- **Flutter/Dart 3.9+** Windows desktop app using **Fluent UI** design
- **State**: Provider-based state management (`lib/state/app_state.dart`)
- **Services**: Core logic in `lib/services/` (github_service, wallpaper_service, settings_service, startup_service)
- **UI**: Pages (`lib/pages/`), widgets (`lib/widgets/`), buttons (`lib/buttons/`)
- **No database**: Uses `shared_preferences` for settings, `flutter_cache_manager` for image caching

## Code Style
- Follow `flutter_lints` rules (configured in `analysis_options.yaml`)
- Use relative imports for project files (e.g., `../utils/helpers.dart`)
- Naming: `snake_case` for files, `camelCase` for variables/functions, `PascalCase` for classes
- Windows-specific: Uses `win32` API for wallpaper setting, `path_provider` for file paths
- Async: Use `async`/`await` pattern; error handling with try-catch

## Cline Rules from .clinerules/Rule.md
- NEVER imply you can examine files that aren't VISIBLE - request them explicitly
- State FileContext (VISIBLE/MENTIONED/INFERRED/UNKNOWN) when discussing files
- Quote minimal excerpts (≤10 lines) with `file:line` context
- Use `[Confidence: LOW/MEDIUM/HIGH]` based on evidence
- Provide minimal diffs; call out environment assumptions
