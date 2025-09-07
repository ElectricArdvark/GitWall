import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
//import 'package:flutter/material.dart' hide FilledButton;
import 'package:gitwall/ui/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:gitwall/ui/welcome_page.dart';
import 'package:gitwall/ui/weekly_page.dart';
import 'package:gitwall/ui/multi_page.dart';
import 'package:gitwall/ui/custom_page.dart';
import '../state/app_state.dart';

// Main home page widget that manages the overall app layout
// Contains navigation sidebar and main content area
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State class for HomePage managing navigation and page control
class _HomePageState extends State<HomePage> {
  // Current navigation tab index (0 = Home, 1 = Settings)
  int _navigationIndex = 0;
  // Controller for managing page views
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize page controller with current navigation index
    _pageController = PageController(initialPage: _navigationIndex);
    // Listen for page changes to update navigation index
    _pageController.addListener(() {
      setState(() {
        _navigationIndex = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    // Clean up page controller resources
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consume the app state to rebuild when it changes
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Row(
          children: [
            // Left sidebar with navigation and tab selection
            LeftSideZone(
              navigationIndex: _navigationIndex,
              onNavigationChanged: (index) => _pageController.jumpToPage(index),
              appState: appState,
            ),
            // Main content area with horizontal page navigation
            Expanded(
              child: PageView(
                // Vertical scrolling disabled for clean page switching
                scrollDirection: Axis.vertical,
                controller: _pageController,
                // Prevent direct page scrolling, use navigation buttons only
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Home content (either welcome or main content)
                  _buildHomePageContent(appState),
                  // Settings page
                  const SettingsPage(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Build the main content based on app state
  // Shows welcome page on first use, main wallpaper view otherwise
  Widget _buildHomePageContent(AppState appState) {
    // Check if welcome screen should be shown (first-time user)
    if (appState.showWelcomeInRightSide) {
      // Return welcome page for new users
      return Consumer<AppState>(
        builder: (context, appState, child) {
          return const WelcomePage();
        },
      );
    }
    // Return main wallpaper content area based on active tab
    switch (appState.activeTab) {
      case 'Weekly':
        return WeeklyPage(appState: appState);
      case 'Multi':
        return MultiPage(appState: appState);
      case 'Custom':
        return CustomPage(appState: appState);
      default:
        return WeeklyPage(appState: appState);
    }
  }
}

const borderColor = Color(0xFF805306);
var leftsidebarColor = const Color(0XFFF6A00C);

class LeftSideZone extends StatelessWidget {
  final int navigationIndex;
  final Function(int) onNavigationChanged;
  final AppState appState;

  const LeftSideZone({
    super.key,
    required this.navigationIndex,
    required this.onNavigationChanged,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 252, // Fixed width for the left sidebar
      child: Container(
        color: leftsidebarColor,
        child: Column(
          children: [
            // Draggable window title bar area
            WindowTitleBarBox(child: MoveWindow()),
            // App title in the sidebar
            const Center(
              child: Text(
                'GitWall',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // Home button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  appState.showWelcomeInRightSide && navigationIndex == 0
                      ? FilledButton(
                        onPressed:
                            () => appState.setShowWelcomeInRightSide(true),
                        child: const Row(
                          children: [
                            Icon(FluentIcons.home),
                            SizedBox(width: 8),
                            Text('Home'),
                          ],
                        ),
                      )
                      : Button(
                        onPressed: () {
                          appState.setShowWelcomeInRightSide(true);
                          onNavigationChanged(0);
                        },
                        child: const Row(
                          children: [
                            Icon(FluentIcons.home),
                            SizedBox(width: 8),
                            Text('Home'),
                          ],
                        ),
                      ),
            ),
            // Settings button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  navigationIndex == 1
                      ? FilledButton(
                        onPressed: () => appState.hideWelcomeInRightSide(),
                        child: const Row(
                          children: [
                            Icon(FluentIcons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      )
                      : Button(
                        onPressed: () {
                          appState.hideWelcomeInRightSide();
                          onNavigationChanged(1);
                        },
                        child: const Row(
                          children: [
                            Icon(FluentIcons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
            ),
            // Tab selection buttons
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: 0.0,
              ),
              child: Column(
                children: [
                  // Weekly button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child:
                        appState.activeTab == 'Weekly'
                            ? FilledButton(
                              onPressed: () {
                                appState.hideWelcomeInRightSide();
                                appState.setActiveTab('Weekly');
                                onNavigationChanged(0);
                              },
                              child: const Text('Weekly'),
                            )
                            : Button(
                              onPressed: () {
                                appState.hideWelcomeInRightSide();
                                appState.setActiveTab('Weekly');
                                onNavigationChanged(0);
                              },
                              child: const Text('Weekly'),
                            ),
                  ),
                  // Multi button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child:
                        appState.activeTab == 'Multi'
                            ? FilledButton(
                              onPressed: () {
                                appState.hideWelcomeInRightSide();
                                appState.setActiveTab('Multi');
                                onNavigationChanged(0);
                              },
                              child: const Text('Multi'),
                            )
                            : Button(
                              onPressed: () {
                                appState.hideWelcomeInRightSide();
                                appState.setActiveTab('Multi');
                                onNavigationChanged(0);
                              },
                              child: const Text('Multi'),
                            ),
                  ),
                  // Custom button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child:
                        appState.activeTab == 'Custom'
                            ? FilledButton(
                              onPressed: () {
                                appState.hideWelcomeInRightSide();
                                appState.setActiveTab('Custom');
                                onNavigationChanged(0);
                              },
                              child: const Text('Custom'),
                            )
                            : Button(
                              onPressed: () {
                                appState.hideWelcomeInRightSide();
                                appState.setActiveTab('Custom');
                                onNavigationChanged(0);
                              },
                              child: const Text('Custom'),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

var buttonColors = WindowButtonColors(
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFFF6A00C),
  mouseDown: const Color(0xFF805306),
  iconMouseOver: const Color(0xFF805306),
  iconMouseDown: const Color(0xFFFFD500),
);

var closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: const Color(0xFFFFFFFF),
);

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
