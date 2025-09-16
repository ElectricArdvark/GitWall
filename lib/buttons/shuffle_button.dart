import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/services/settings_service.dart';
import '../state/app_state.dart';

class ShuffleButton extends StatefulWidget {
  final AppState appState;

  const ShuffleButton({super.key, required this.appState});

  @override
  State<ShuffleButton> createState() => _ShuffleButtonState();
}

class _ShuffleButtonState extends State<ShuffleButton> {
  bool _autoShuffleEnabled = true;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadShuffleState();
  }

  Future<void> _loadShuffleState() async {
    _autoShuffleEnabled = await _settingsService.getAutoShuffle();
    setState(() {});
  }

  Future<void> _toggleAutoShuffle() async {
    final newValue = !_autoShuffleEnabled;
    await _settingsService.setAutoShuffle(newValue);
    setState(() {
      _autoShuffleEnabled = newValue;
    });
    // Use the new public method to restart the scheduler
    await widget.appState.restartScheduler();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Toggle auto shuffle',
      child: Button(
        onPressed: _toggleAutoShuffle,
        child: Icon(
          _autoShuffleEnabled ? FluentIcons.repeat_all : FluentIcons.repeat_one,
          color: widget.appState.isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
