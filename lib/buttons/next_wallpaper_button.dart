import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import '../state/app_state.dart';

class NextWallpaperButton extends StatelessWidget {
  final AppState appState;

  const NextWallpaperButton({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Set next wallpaper',
      child: Button(
        onPressed: () => appState.setNextWallpaper(),
        child: Icon(
          FluentIcons.next,
          color: appState.isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
