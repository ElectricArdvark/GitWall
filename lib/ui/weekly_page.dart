import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:gitwall/ui/home_page.dart';
import '../state/app_state.dart';

const rightbackgroundStartColor = Color(0xFFFFD500);
const rightbackgroundEndColor = Color(0xFFF6A00C);
const borderColor = Color(0xFF805306);

class WeeklyPage extends StatefulWidget {
  final AppState appState;
  const WeeklyPage({super.key, required this.appState});

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage> {
  @override
  Widget build(BuildContext context) {
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
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: SizedBox(
                    height: 20,
                    child: Center(
                      child: Text(
                        'Uses the default repository for weekly wallpapers.',
                      ),
                    ),
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
                if (!widget.appState.hideStatus)
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
