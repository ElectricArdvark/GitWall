import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/base_page.dart';
import '../state/app_state.dart';

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
      color: const Color(0xFF1F2A29),
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
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Text(
                    'Wallpaper Preview:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF2D3A3A)),
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
                                child: Text(
                                  'No wallpaper preview available.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
