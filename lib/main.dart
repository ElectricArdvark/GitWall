import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'constants.dart';
import 'ui/home_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Configure the window manager for a custom look.
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(650, 535),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: appTitle,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setMinimumSize(const Size(650, 535));
    await windowManager.setMaximumSize(const Size(650, 535));
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the AppState to the entire widget tree.
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: FluentApp(
        title: appTitle,
        theme: FluentThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.blue,
          visualDensity: VisualDensity.standard,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
