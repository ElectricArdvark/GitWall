import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/ui/home_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';

// Settings page widget for managing GitWall application configuration
// Allows users to set wallpaper resolution, change interval, autostart, and custom repo URL
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Local state variables for managing form selections
  String? _selectedResolution;
  int? _selectedIntervalMinutes;
  // Controller for custom repository URL text input
  late TextEditingController _customUrlController;
  // Controller for custom wallpaper location text input
  late TextEditingController _customWallpaperLocationController;
  // Controller for GitHub token text input
  late TextEditingController _githubTokenController;

  @override
  void initState() {
    super.initState();
    // Initialize local state with current app state values
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedResolution = appState.currentResolution;
    _selectedIntervalMinutes = appState.wallpaperIntervalMinutes;
    _customUrlController = TextEditingController(text: appState.customRepoUrl);
    _customWallpaperLocationController = TextEditingController(
      text: appState.customWallpaperLocation ?? '',
    );
    _githubTokenController = TextEditingController(text: appState.githubToken);
  }

  @override
  void dispose() {
    // Clean up text controller resources
    _customUrlController.dispose();
    _customWallpaperLocationController.dispose();
    _githubTokenController.dispose();
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

  Future<void> _pickDirectory() async {
    final appState = Provider.of<AppState>(context, listen: false);

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      appState.setCustomWallpaperLocation(selectedDirectory);
      _customWallpaperLocationController.text = selectedDirectory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD500), Color(0xFFF6A00C)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return Column(
            children: [
              WindowTitleBarBox(
                child: Row(
                  children: [Expanded(child: MoveWindow()), WindowButtons()],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
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
                            if (newValue != null) {
                              _selectedResolution = newValue;
                              final appState = Provider.of<AppState>(
                                context,
                                listen: false,
                              );
                              appState.updateResolution(newValue);
                            }
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
                            if (newValue != null) {
                              _selectedIntervalMinutes = newValue;
                              final appState = Provider.of<AppState>(
                                context,
                                listen: false,
                              );
                              appState.updateWallpaperInterval(newValue);
                            }
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
                        ToggleSwitch(
                          checked: appState.hideStatus,
                          onChanged: (v) => appState.toggleHideStatus(v),
                          content: const Text('Hide status messages'),
                        ),
                        const SizedBox(height: 30),
                        ToggleSwitch(
                          checked: appState.useCachedWhenNoInternet,
                          onChanged:
                              (v) => appState.toggleUseCachedWhenNoInternet(v),
                          content: const Text(
                            'Use cached images when no internet or no file available',
                          ),
                        ),
                        const SizedBox(height: 30),
                        ToggleSwitch(
                          checked: appState.autoShuffleEnabled,
                          onChanged: (v) => appState.toggleAutoShuffle(v),
                          content: const Text('Enable auto-shuffle wallpapers'),
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
                          onChanged:
                              (value) => appState.setCustomRepoUrl(value),
                        ),
                        const SizedBox(height: 30),
                        const Text('GitHub Token'),
                        const SizedBox(height: 8.0),
                        TextBox(
                          controller: _githubTokenController,
                          placeholder: 'Enter GitHub token for private repos',
                          onChanged: (value) => appState.setGithubToken(value),
                        ),
                        const SizedBox(height: 30),
                        const Text('Wallpaper Storage Location'),
                        const SizedBox(height: 8.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.customWallpaperLocation != null &&
                                      appState
                                          .customWallpaperLocation!
                                          .isNotEmpty
                                  ? 'Current: ${appState.customWallpaperLocation}'
                                  : 'Current: Default (AppData/Local/GitWall/Wallpapers)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                FilledButton(
                                  onPressed: _pickDirectory,
                                  child: const Text('Choose Folder'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextBox(
                                    controller:
                                        _customWallpaperLocationController,
                                    placeholder:
                                        'Selected folder path will appear here',
                                    readOnly: true,
                                  ),
                                ),
                                if (appState.customWallpaperLocation != null &&
                                    appState
                                        .customWallpaperLocation!
                                        .isNotEmpty)
                                  Tooltip(
                                    message: 'Clear custom location',
                                    child: IconButton(
                                      icon: const Icon(FluentIcons.clear),
                                      onPressed: () {
                                        appState.setCustomWallpaperLocation(
                                          null,
                                        );
                                        _customWallpaperLocationController
                                            .clear();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
