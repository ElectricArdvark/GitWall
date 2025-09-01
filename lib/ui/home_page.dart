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
            automaticallyImplyLeading: false,
            height: 0,
          ),
          pane: NavigationPane(
            selected: _navigationIndex,
            onChanged: (index) => setState(() => _navigationIndex = index),
            displayMode: PaneDisplayMode.compact,
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
          ),
        );
      },
    );
  }

  Widget _buildHomePageContent(AppState appState) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Status')),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Status Update',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(appState.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => appState.updateWallpaper(isManual: true),
              child: const Text('Force Refresh Now'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Current Wallpaper Preview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
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
                          fit: BoxFit.cover,
                          // Add a key to force rebuild when the file changes
                          key: ValueKey(appState.currentWallpaperFile!.path),
                        )
                        : const Center(
                          child: Text('No wallpaper preview available.'),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
