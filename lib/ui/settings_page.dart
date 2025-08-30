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
  late TextEditingController _repoUrlController;
  String? _selectedResolution;

  @override
  void initState() {
    super.initState();
    // Initialize controller with the current URL from the state
    _repoUrlController = TextEditingController(
      text: Provider.of<AppState>(context, listen: false).repoUrl,
    );
    _selectedResolution =
        Provider.of<AppState>(context, listen: false).currentResolution;
  }

  @override
  void dispose() {
    _repoUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_repoUrlController.text.isNotEmpty) {
      appState.updateRepoUrl(_repoUrlController.text);
    }
    if (_selectedResolution != null) {
      appState.updateResolution(_selectedResolution!);

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
      header: const PageHeader(title: Text('Settings')),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GitHub Repository URL'),
                const SizedBox(height: 8.0),
                TextBox(
                  controller: _repoUrlController,
                  placeholder: 'e.g., https://github.com/user/repo',
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'The repository must be public and contain images named in the format: DayOfWeek-Resolution.png (e.g., Monday-1920x1080.png)',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 24.0),
                FilledButton(
                  onPressed: _saveSettings,
                  child: const Text('Save and Refresh'),
                ),
                const SizedBox(height: 24.0),
                const Text('Wallpaper Resolution'),
                const SizedBox(height: 8.0),
                ComboBox<String>(
                  value: _selectedResolution,
                  items:
                      <String>[
                        '1920x1080',
                        '1366x768',
                        '1440x900',
                        '1536x864',
                        '1600x900',
                        '1680x1050',
                        '2560x1440',
                        '3840x2160',
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
                        Uri.parse('https://github.com/ElectricArdvark/GitWall'),
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
