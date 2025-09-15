import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import '../state/app_state.dart';

class ShuffleButton extends StatelessWidget {
  final AppState appState;

  const ShuffleButton({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Toggle auto shuffle',
      child: Button(
        onPressed:
            () => appState.toggleAutoShuffle(!appState.autoShuffleEnabled),
        child: Icon(
          appState.autoShuffleEnabled
              ? FluentIcons.repeat_all
              : FluentIcons.repeat_one,
          color: appState.isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
