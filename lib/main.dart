import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/state/app_state.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'ui/home_page.dart';

void main() async {
  runApp(const MyApp());
  doWhenWindowReady(() {
    const initialSize = Size(800, 445);
    appWindow.minSize = initialSize; //Size(800, 440);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "GitWall";
    appWindow.show();
  });
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
