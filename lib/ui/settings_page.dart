import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors, Scrollbar;
import 'package:flutter/material.dart'
    show Theme, ThemeData, Colors, Scaffold, Scrollbar;
import 'package:gitwall/ui/base_page.dart';
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
  late TextEditingController _customWallpaperLocationController;
  late TextEditingController _githubTokenController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    _customUrlController.dispose();
    _customWallpaperLocationController.dispose();
    _githubTokenController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1F2A29),
        cardColor: const Color(0xFF2D3A3A),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1F2A29),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            return Column(
              children: [
                WindowTitleBarBox(
                  child: Row(
                    children: [
                      Expanded(child: MoveWindow()),
                      const WindowButtons(),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    thickness: 8.0,
                    controller: _scrollController,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingsCard(
                              title: 'General',
                              children: [
                                _SettingsItem(
                                  label: 'Run on startup',
                                  child: ToggleSwitch(
                                    checked: appState.autostartEnabled,
                                    onChanged:
                                        (v) => appState.toggleAutostart(v),
                                  ),
                                ),
                                _SettingsItem(
                                  label: 'Hide status messages',
                                  child: ToggleSwitch(
                                    checked: appState.hideStatus,
                                    onChanged:
                                        (v) => appState.toggleHideStatus(v),
                                  ),
                                ),
                                _SettingsItem(
                                  label: 'Minimize to tray on close',
                                  child: ToggleSwitch(
                                    checked: appState.closeToTrayEnabled,
                                    onChanged:
                                        (v) => appState.toggleCloseToTray(v),
                                  ),
                                ),
                                _SettingsItem(
                                  label: 'Start minimized',
                                  child: ToggleSwitch(
                                    checked: appState.startMinimizedEnabled,
                                    onChanged:
                                        (v) => appState.toggleStartMinimized(v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _SettingsCard(
                              title: 'Wallpaper',
                              children: [
                                _SettingsItem(
                                  label: 'Resolution',
                                  child: ComboBox<String>(
                                    value: _selectedResolution,
                                    items:
                                        [
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
                                        ].map<ComboBoxItem<String>>((
                                          String value,
                                        ) {
                                          return ComboBoxItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(
                                          () => _selectedResolution = newValue,
                                        );
                                        appState.updateResolution(newValue);
                                      }
                                    },
                                  ),
                                ),
                                _SettingsItem(
                                  label: 'Change Interval',
                                  child: ComboBox<int>(
                                    value: _selectedIntervalMinutes,
                                    items:
                                        [
                                          1,
                                          15,
                                          30,
                                          60,
                                          180,
                                          360,
                                          720,
                                          1440,
                                        ].map<ComboBoxItem<int>>((int value) {
                                          String text;
                                          if (value < 60)
                                            text = '$value minutes';
                                          else if (value == 60)
                                            text = '1 hour';
                                          else
                                            text = '${value ~/ 60} hours';
                                          return ComboBoxItem<int>(
                                            value: value,
                                            child: Text(text),
                                          );
                                        }).toList(),
                                    onChanged: (int? newValue) {
                                      if (newValue != null) {
                                        setState(
                                          () =>
                                              _selectedIntervalMinutes =
                                                  newValue,
                                        );
                                        appState.updateWallpaperInterval(
                                          newValue,
                                        );
                                      }
                                    },
                                  ),
                                ),

                                _SettingsItem(
                                  label: 'Storage Location',
                                  child: Tooltip(
                                    message:
                                        'Choose custom wallpaper storage location',
                                    child: Button(
                                      onPressed: _pickDirectory,
                                      child: Text(
                                        appState.customWallpaperLocation ??
                                            'Choose Folder',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _SettingsCard(
                              title: 'Repository',
                              children: [
                                _SettingsItem(
                                  label: 'Custom URL',
                                  child: TextBox(
                                    controller: _customUrlController,
                                    placeholder: 'Enter custom repository URL',
                                    onChanged:
                                        (value) =>
                                            appState.setCustomRepoUrl(value),
                                  ),
                                ),
                                _SettingsItem(
                                  label: 'GitHub Token',
                                  child: TextBox(
                                    controller: _githubTokenController,
                                    placeholder:
                                        'Enter token for private repos',
                                    onChanged:
                                        (value) =>
                                            appState.setGithubToken(value),
                                  ),
                                ),
                                Tooltip(
                                  message:
                                      'Open the default GitWall repository in browser',
                                  child: HyperlinkButton(
                                    child: const Text(
                                      'View Default GitWall Repository',
                                    ),
                                    onPressed:
                                        () => launchUrl(
                                          Uri.parse(
                                            'https://github.com/ElectricArdvark/GitWall-WP',
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Card(
          backgroundColor: const Color(0xFF2D3A3A),
          padding: const EdgeInsets.all(16.0),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsItem({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(width: 150, child: child),
        ],
      ),
    );
  }
}
