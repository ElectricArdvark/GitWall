import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/state/app_state.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'ui/home_page.dart';

// Entry point of the application
void main() async {
  // Initialize and run the Flutter app
  runApp(const MyApp());

  // Configure the desktop window appearance and behavior when ready
  doWhenWindowReady(() {
    // Set the initial window dimensions
    const initialSize = Size(1000, 445);
    // Set minimum and current window size
    appWindow.minSize = initialSize; //Size(800, 440);
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
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the AppState to the entire widget tree using Provider pattern
    // This allows all child widgets to access and react to app state changes
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: FluentApp(
        // Set application title from constants
        title: appTitle,
        // Configure Fluent UI dark theme
        theme: FluentThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.blue,
          visualDensity: VisualDensity.standard,
        ),
        // Set the initial home page
        home: const HomePage(),
        // Hide debug banner in development
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
