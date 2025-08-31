import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/ui/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../state/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  final SystemTray _systemTray = SystemTray();
  int _navigationIndex = 0;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initSystemTray();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    // Instead of closing, hide the window to the system tray
    windowManager.hide();
  }

  Future<void> _initSystemTray() async {
    await _systemTray.initSystemTray(iconPath: 'assets/app_icon.ico');
    await _systemTray.setTitle("GitWall");
    await _systemTray.setToolTip("GitWall - Dynamic Wallpaper Changer");

    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Open GitWall',
        onClicked: (_) => windowManager.show(),
      ),
      MenuItemLabel(
        label: 'Force Refresh',
        onClicked:
            (_) => context.read<AppState>().updateWallpaper(isManual: true),
      ),
      MenuSeparator(),
      MenuItemLabel(label: 'Exit', onClicked: (_) => windowManager.destroy()),
    ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return NavigationView(
          appBar: const NavigationAppBar(
            title: Text('GitWall'),
            automaticallyImplyLeading: false,
          ),
          pane: NavigationPane(
            size: const NavigationPaneSize(openMaxWidth: 220),
            selected: _navigationIndex,
            onChanged: (index) => setState(() => _navigationIndex = index),
            displayMode: PaneDisplayMode.minimal,
            items: [
              PaneItem(
                icon: const Icon(FluentIcons.home),
                title: const Text('Home'),
                body: _buildHomePageContent(appState),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.settings),
                title: const Text('Settings'),
                body: const SettingsPage(),
              ),
            ],
            footerItems: [
              PaneItemHeader(
                header: Padding(
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomePageContent(AppState appState) {
    const tabs = ['Weekly', 'Multi', 'Custom'];

    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(tabs.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child:
                            _selectedTabIndex == index
                                ? FilledButton(
                                  onPressed: () {},
                                  child: Text(tabs[index]),
                                )
                                : Button(
                                  onPressed:
                                      () => setState(
                                        () => _selectedTabIndex = index,
                                      ),
                                  child: Text(tabs[index]),
                                ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 20,
                    child: IndexedStack(
                      index: _selectedTabIndex,
                      children: const [
                        Center(
                          child: Text(
                            'Uses the default repository for weekly wallpapers.',
                          ),
                        ),
                        Center(
                          child: Text(
                            'Uses a repository with multiple resolutions.',
                          ),
                        ),
                        Center(child: Text('Uses a custom repository URL.')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Wallpaper Preview:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 300,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[100]),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child:
                  appState.currentWallpaperFile != null &&
                          appState.currentWallpaperFile!.existsSync()
                      ? Image.file(
                        appState.currentWallpaperFile!,
                        fit: BoxFit.fill,
                        key: ValueKey(appState.currentWallpaperFile!.path),
                      )
                      : const Center(
                        child: Text('No wallpaper preview available.'),
                      ),
            ),
          ),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text('Status: ${appState.status}'),
            const Spacer(),
            FilledButton(
              onPressed: () => appState.updateWallpaper(isManual: true),
              child: const Text('Force Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
