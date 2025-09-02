import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' hide FilledButton;
import 'package:gitwall/ui/settings_page.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navigationIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _navigationIndex = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Row(
          children: [
            LeftSideZone(
              navigationIndex: _navigationIndex,
              onNavigationChanged: (index) => _pageController.jumpToPage(index),
              appState: appState,
            ),
            Expanded(
              child: PageView(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHomePageContent(appState),
                  const SettingsPage(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomePageContent(AppState appState) {
    return RightSideZone(appState: appState);
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
      width: 252,
      child: Container(
        color: leftsidebarColor,
        child: Column(
          children: [
            WindowTitleBarBox(child: MoveWindow()),
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
                  navigationIndex == 0
                      ? FilledButton(
                        onPressed: () {},
                        child: const Row(
                          children: [
                            Icon(FluentIcons.home),
                            SizedBox(width: 8),
                            Text('Home'),
                          ],
                        ),
                      )
                      : Button(
                        onPressed: () => onNavigationChanged(0),
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
                        onPressed: () {},
                        child: const Row(
                          children: [
                            Icon(FluentIcons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      )
                      : Button(
                        onPressed: () => onNavigationChanged(1),
                        child: const Row(
                          children: [
                            Icon(FluentIcons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
            ),
            // Footer dropdown
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropDownButton(
                title: Text(appState.activeTab),
                items: [
                  MenuFlyoutItem(
                    text: const Text('Weekly'),
                    onPressed: () => appState.setActiveTab('Weekly'),
                  ),
                  MenuFlyoutItem(
                    text: const Text('Multi'),
                    onPressed: () => appState.setActiveTab('Multi'),
                  ),
                  MenuFlyoutItem(
                    text: const Text('Custom'),
                    onPressed: () => appState.setActiveTab('Custom'),
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

const rightbackgroundStartColor = Color(0xFFFFD500);
const rightbackgroundEndColor = Color(0xFFF6A00C);

class RightSideZone extends StatefulWidget {
  final AppState appState;
  const RightSideZone({super.key, required this.appState});

  @override
  State<RightSideZone> createState() => _RightSideZoneState();
}

class _RightSideZoneState extends State<RightSideZone> {
  String _getDescription(String tab) {
    switch (tab) {
      case 'Weekly':
        return 'Uses the default repository for weekly wallpapers.';
      case 'Multi':
        return 'Uses a repository with multiple resolutions.';
      case 'Custom':
        return 'Uses a custom repository URL.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    String description = _getDescription(widget.appState.activeTab);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rightbackgroundStartColor, rightbackgroundEndColor],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        children: [
          WindowTitleBarBox(
            child: Row(
              children: [Expanded(child: MoveWindow()), const WindowButtons()],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: SizedBox(
                    height: 20,
                    child: Center(child: Text(description)),
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Text(
                    'Wallpaper Preview:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: SizedBox(
                    height: 300,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child:
                          widget.appState.currentWallpaperFile != null &&
                                  widget.appState.currentWallpaperFile!
                                      .existsSync()
                              ? Image.file(
                                widget.appState.currentWallpaperFile!,
                                fit: BoxFit.fill,
                                key: ValueKey(
                                  widget.appState.currentWallpaperFile!.path,
                                ),
                              )
                              : const Center(
                                child: Text('No wallpaper preview available.'),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 10.0,
              top: 8.0,
            ),
            child: Row(
              children: [
                Text('Status: ${widget.appState.status}'),
                const Spacer(),
                FilledButton(
                  onPressed:
                      () => widget.appState.updateWallpaper(isManual: true),
                  child: const Text('Force Refresh'),
                ),
              ],
            ),
          ),
        ],
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
