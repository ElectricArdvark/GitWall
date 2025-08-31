import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedResolution;
  int? _selectedIntervalMinutes;
  late TextEditingController _customUrlController;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedResolution = appState.currentResolution;
    _selectedIntervalMinutes = appState.wallpaperIntervalMinutes;
    _customUrlController = TextEditingController(text: appState.customRepoUrl);
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_selectedResolution != null) {
      appState.updateResolution(_selectedResolution!);
    }
    if (_selectedIntervalMinutes != null) {
      appState.updateWallpaperInterval(_selectedIntervalMinutes!);

      // Show a confirmation message
      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Settings Saved'),
            content: const Text(
              'Repository URL updated. Attempting to fetch new wallpaper...',
            ),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
            severity: InfoBarSeverity.success,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      content: Consumer<AppState>(
        builder: (context, appState, child) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wallpaper Resolution'),
                const SizedBox(height: 8.0),
                ComboBox<String>(
                  value: _selectedResolution,
                  items:
                      <String>[
                        '3840x2160',
                        '2560x1440',
                        '1920x1080',
                        '1680x1050',
                        '1600x900',
                        '1536x864',
                        '1440x900',
                        '1366x768',
                        '1280x1024',
                        '1280x720',
                        '800x600',
                        '720x648',
                      ].map<ComboBoxItem<String>>((String value) {
                        return ComboBoxItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedResolution = newValue;
                    });
                  },
                ),
                const SizedBox(height: 24.0),
                const Text('Wallpaper Change Interval'),
                const SizedBox(height: 8.0),
                ComboBox<int>(
                  value: _selectedIntervalMinutes,
                  items:
                      <int>[
                        1,
                        15, // 15 minutes
                        30, // 30 minutes
                        60, // 1 hour
                        180, // 3 hours
                        360, // 6 hours
                        720, // 12 hours
                        1440, // 24 hours
                      ].map<ComboBoxItem<int>>((int value) {
                        String text;
                        if (value < 60) {
                          text = '$value minutes';
                        } else if (value == 60) {
                          text = '1 hour';
                        } else {
                          text = '${value ~/ 60} hours';
                        }
                        return ComboBoxItem<int>(
                          value: value,
                          child: Text(text),
                        );
                      }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedIntervalMinutes = newValue;
                    });
                  },
                ),
                const SizedBox(height: 30),
                FilledButton(
                  onPressed: _saveSettings,
                  child: const Text('Save and Refresh'),
                ),
                const SizedBox(height: 30),
                ToggleSwitch(
                  checked: appState.autostartEnabled,
                  onChanged: (v) => appState.toggleAutostart(v),
                  content: const Text('Run GitWall on Windows startup'),
                ),
                const SizedBox(height: 30),
                HyperlinkButton(
                  child: const Text('View Default GitWall Repository'),
                  onPressed:
                      () => launchUrl(
                        Uri.parse(
                          'https://github.com/ElectricArdvark/GitWall-WP',
                        ),
                      ),
                ),
                const SizedBox(height: 30),
                const Text('Custom Repository URL'),
                const SizedBox(height: 8.0),
                TextBox(
                  controller: _customUrlController,
                  placeholder: 'Enter custom repository URL',
                  onChanged: (value) => appState.setCustomRepoUrl(value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
