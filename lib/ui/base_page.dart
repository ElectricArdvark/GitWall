import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
//import 'package:flutter/material.dart' hide FilledButton;
import 'package:gitwall/ui/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:gitwall/ui/welcome_page.dart';
import 'package:gitwall/ui/weekly_page.dart';
import 'package:gitwall/ui/multi_page.dart';
import 'package:gitwall/ui/custom_page.dart';
import 'package:gitwall/ui/cached_page.dart';
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
      case 'Saved':
        return CachedPage(appState: appState);
      default:
        return WeeklyPage(appState: appState);
    }
  }
}

const borderColor = Color(0xFF1F2A29);
var leftsidebarColor = const Color(0xFF1F2A29);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Draggable window title bar area
            WindowTitleBarBox(child: SizedBox(height: 48, child: MoveWindow())),
            // App title in the sidebar
            const Padding(
              padding: EdgeInsets.only(left: 75.0, top: 16.0, bottom: 32.0),
              child: Text(
                'GitWall',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            // Navigation items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NavigationItem(
                      icon: FluentIcons.home,
                      text: 'Home',
                      isSelected:
                          appState.showWelcomeInRightSide &&
                          navigationIndex == 0,
                      onTap: () {
                        appState.setShowWelcomeInRightSide(true);
                        onNavigationChanged(0);
                      },
                    ),
                    _NavigationItem(
                      icon: FluentIcons.settings,
                      text: 'Settings',
                      isSelected: navigationIndex == 1,
                      onTap: () {
                        appState.hideWelcomeInRightSide();
                        onNavigationChanged(1);
                      },
                    ),
                    const SizedBox(height: 24),
                    // Tab selection buttons
                    _NavigationItem(
                      icon: FluentIcons.calendar_week,
                      text: 'Weekly',
                      isSelected:
                          appState.activeTab == 'Weekly' &&
                          navigationIndex == 0,
                      onTap: () {
                        appState.hideWelcomeInRightSide();
                        appState.setActiveTab('Weekly');
                        onNavigationChanged(0);
                      },
                    ),
                    _NavigationItem(
                      icon: FluentIcons.slideshow,
                      text: 'Multi',
                      isSelected:
                          appState.activeTab == 'Multi' && navigationIndex == 0,
                      onTap: () {
                        appState.hideWelcomeInRightSide();
                        appState.setActiveTab('Multi');
                        onNavigationChanged(0);
                      },
                    ),
                    _NavigationItem(
                      icon: FluentIcons.edit_create,
                      text: 'Custom',
                      isSelected:
                          appState.activeTab == 'Custom' &&
                          navigationIndex == 0,
                      onTap: () {
                        appState.hideWelcomeInRightSide();
                        appState.setActiveTab('Custom');
                        onNavigationChanged(0);
                      },
                    ),
                    _NavigationItem(
                      icon: FluentIcons.download,
                      text: 'Saved',
                      isSelected:
                          appState.activeTab == 'Saved' && navigationIndex == 0,
                      onTap: () {
                        appState.hideWelcomeInRightSide();
                        appState.setActiveTab('Saved');
                        onNavigationChanged(0);
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Status and Force Refresh section
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                top: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!appState.hideStatus)
                    Text(
                      'Status: ${appState.status}',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: 'Force refresh the wallpaper',
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            () => appState.updateWallpaper(isManual: true),
                        child: const Text('Force Refresh'),
                      ),
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

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D3A3A) : null,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
              const SizedBox(width: 16),
              Text(
                text,
                style: const TextStyle(fontSize: 16, color: Color(0xFFFFFFFF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
