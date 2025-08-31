# v1.0.9

- Modified padding in _buildHomePageContent in lib/ui/home_page.dart: changed from EdgeInsets.all(8.0) to EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0) to reduce gap between NavigationAppBar and home page content.

# v1.0.8

- Added NavigationAppBar to NavigationView to ensure the navigation pane toggle button is visible when using PaneDisplayMode.minimal

# v1.0.7

- Replaced ComboBox with DropDownButton in NavigationPane footer for more compact design and better space utilization
- Optimized NavigationPane width to 220px (down from 280px) since DropDownButton requires less horizontal space

# v1.0.6

- Moved the force refresh button to the bottom next to the status.
- Moved the custom URL field back to the settings page.
- Adjusted tab descriptions to be compact under the tabs without taking excessive space.

# v1.0.5

- Moved the status update to the bottom of the home page and reformatted it.

# v1.0.4

- Decoupled tab selection from the active wallpaper source.
- Moved the active wallpaper source selection `ComboBox` to the `NavigationPane`'s `footerItems`.

# v1.0.3

- Replaced the `TabView` with a custom `TabBar` implementation using `fluent_ui` widgets for a more native Windows look and feel.

# v1.0.2

- Implemented a tabbed interface on the home page with "Weekly," "Multi," and "Custom" tabs.
- The "Weekly" tab uses the default wallpaper repository.
- The "Multi" tab uses a repository with wallpapers organized by resolution.
- The "Custom" tab allows users to enter a custom GitHub repository URL.
- Removed the repository URL setting from the settings page.
- Added an option to select the active wallpaper source (Weekly, Multi, or Custom).

# v1.0.1

- Set a fixed window size for the application.
