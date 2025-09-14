import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'constants.dart';
import 'ui/base_page.dart';

// Entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Initialize and run the Flutter app
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );

  // Configure the desktop window appearance and behavior when ready
  doWhenWindowReady(() {
    // Set the initial window dimensions
    const initialSize = Size(1000, 500);
    // Set minimum and current window size
    appWindow.minSize = initialSize; //Size(800, 445);
    appWindow.size = initialSize;
    // Center the window on screen
    appWindow.alignment = Alignment.center;
    // Set the window title
    appWindow.title = "GitWall";
    // Make the window visible
    appWindow.show();
  });
}

// Root widget of the application
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _init();
  }

  Future<void> _init() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await trayManager.setIcon('lib/assets/logo.ico');
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show Window'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit App'),
      ],
    );
    await trayManager.setContextMenu(menu);

    await windowManager.setPreventClose(true);
    setState(() {});

    if (appState.startMinimizedEnabled) {
      windowManager.hide();
    } else {
      windowManager.show();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the AppState to the entire widget tree using Provider pattern
    // This allows all child widgets to access and react to app state changes
    return FluentApp(
      // Set application title from constants
      title: appTitle,
      // Configure Fluent UI dark theme
      theme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
      ),
      // Set the initial home page
      home: const BasePage(),
      // Hide debug banner in development
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  void onWindowClose() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.saveStateBeforeClose();
    if (appState.closeToTrayEnabled) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      windowManager.hide();
    } else {
      windowManager.show();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      windowManager.show();
    } else if (menuItem.key == 'exit_app') {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.saveStateBeforeClose();
      windowManager.destroy();
    }
  }
}
