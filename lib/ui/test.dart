import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';

class SeingsPage extends StatefulWidget {
  const SeingsPage({super.key});

  @override
  State<SeingsPage> createState() => _SeingsPageState();
}

class _SeingsPageState extends State<SeingsPage> {
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

  void _saveSeings() {
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
      content: Consumer<AppState>(
        builder: (context, appState, child) {
          return const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('This is a test page')],
          );
        },
      ),
    );
  }
}
