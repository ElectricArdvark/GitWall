import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/services/settings_service.dart';
import 'package:gitwall/services/startup_service.dart';
import 'package:intl/intl.dart';
import '../constants.dart'; // Import constants.dart
import '../services/cache_service.dart';
import '../services/github_service.dart';
import '../services/wallpaper_service.dart';
import '../utils/helpers.dart';

class AppState extends ChangeNotifier {
  // Services
  final GitHubService _githubService = GitHubService();
  final CacheService _cacheService = CacheService();
  final WallpaperService _wallpaperService = WallpaperService();
  final SettingsService _settingsService = SettingsService();
  final StartupService _startupService = StartupService();

  // State
  String _status = "Initializing...";
  String get status => _status;

  String _repoUrl = "";
  String get repoUrl => _repoUrl;

  String _customRepoUrl = "";
  String get customRepoUrl => _customRepoUrl;

  String _activeTab = "Weekly";
  String get activeTab => _activeTab;

  File? _currentWallpaperFile;
  File? get currentWallpaperFile => _currentWallpaperFile;

  bool _autostartEnabled = true;
  bool get autostartEnabled => _autostartEnabled;

  String _currentResolution = '1920x1080'; // Default value
  String get currentResolution => _currentResolution;

  int _wallpaperIntervalMinutes = 60; // Default to 60 minutes
  int get wallpaperIntervalMinutes => _wallpaperIntervalMinutes;

  bool _showWelcomeInRightSide =
      true; // Always show welcome initially in right side
  bool get showWelcomeInRightSide => _showWelcomeInRightSide;

  Timer? _timer;

  AppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    _repoUrl = await _settingsService.getRepoUrl();
    _customRepoUrl = await _settingsService.getCustomRepoUrl();
    _activeTab = await _settingsService.getActiveTab();
    _autostartEnabled = await _settingsService.isAutostartEnabled();
    _currentResolution = await _settingsService.getResolution();
    _wallpaperIntervalMinutes = await _settingsService.getWallpaperInterval();
    // No need to load welcome state from persistence anymore
    updateAutostart();
    await updateWallpaper(isManual: false);
    _startScheduler();
    notifyListeners();
  }

  void _startScheduler() {
    // Cancel any existing timer
    _timer?.cancel();
    // Check every hour
    _timer = Timer.periodic(Duration(minutes: _wallpaperIntervalMinutes), (
      Timer timer,
    ) {
      // print(
      //   "Scheduler check running (interval: $_wallpaperIntervalMinutes minutes)...",
      // );
      updateWallpaper(isManual: false);
    });
  }

  Future<void> updateRepoUrl(String newUrl) async {
    _repoUrl = newUrl;
    await _settingsService.saveRepoUrl(newUrl);
    notifyListeners();
    // Trigger an update with the new repository
    await updateWallpaper(isManual: true);
  }

  Future<void> setCustomRepoUrl(String url) async {
    _customRepoUrl = url;
    await _settingsService.saveCustomRepoUrl(url);
    notifyListeners();
    if (_activeTab == 'Custom') {
      await updateWallpaper(isManual: true);
    }
  }

  Future<void> setActiveTab(String tab) async {
    _activeTab = tab;
    await _settingsService.saveActiveTab(tab);
    notifyListeners();
    await updateWallpaper(isManual: true);
  }

  Future<void> toggleAutostart(bool enabled) async {
    _autostartEnabled = enabled;
    await _settingsService.setAutostart(enabled);
    updateAutostart();
    notifyListeners();
  }

  Future<void> updateWallpaperInterval(int minutes) async {
    _wallpaperIntervalMinutes = minutes;
    await _settingsService.saveWallpaperInterval(minutes);
    _startScheduler(); // Restart scheduler with new interval
    notifyListeners();
  }

  void hideWelcomeInRightSide() {
    _showWelcomeInRightSide = false;
    notifyListeners();
  }

  void updateAutostart() {
    if (_autostartEnabled) {
      _startupService.enableAutostart();
    } else {
      _startupService.disableAutostart();
    }
  }

  Future<void> updateResolution(String newResolution) async {
    _currentResolution = newResolution;
    await _settingsService.saveResolution(newResolution);
    notifyListeners();
    await updateWallpaper(isManual: true);
  }

  Future<void> updateWallpaper({bool isManual = false}) async {
    _updateStatus("Checking for new wallpaper...");

    try {
      final day = getCurrentDay();
      final resolution = await _settingsService.getResolution();

      File? savedFile;
      late WallpaperDownloadResult
      downloadResult; // Changed to late and non-nullable
      String? downloadedFileName;

      String repoUrlToUse;
      switch (_activeTab) {
        case 'Weekly':
          repoUrlToUse = defaultRepoUrl;
          break;
        case 'Multi':
          repoUrlToUse = 'https://github.com/ElectricArdvark/GitWall-WP';
          break;
        case 'Custom':
          repoUrlToUse = _customRepoUrl;
          break;
        default:
          repoUrlToUse = defaultRepoUrl;
      }

      if (repoUrlToUse.isEmpty) {
        _updateStatus("Custom repository URL is not set.");
        return;
      }

      if (_activeTab == 'Weekly') {
        for (final ext in supportedImageExtensions) {
          final fileNameForDefaultRepo = '${day}_$resolution$ext';
          final localFile = await _cacheService.getLocalFile(
            fileNameForDefaultRepo,
          );

          if (!isManual && await localFile.exists()) {
            _updateStatus(
              "Today's wallpaper is already set. Next check scheduled.",
              file: localFile,
            );
            return;
          }

          _updateStatus("Downloading wallpaper for $day ($resolution)$ext...");
          downloadResult = await _githubService.downloadWallpaper(
            repoUrlToUse,
            day,
            resolution,
            ext,
          );

          if (downloadResult.response.statusCode == 200) {
            savedFile = await _cacheService.saveFile(
              fileNameForDefaultRepo,
              downloadResult.response.bodyBytes,
            );
            downloadedFileName = downloadResult.fileName;
            break;
          } else if (downloadResult.response.statusCode != 404) {
            throw Exception(
              "Failed to download wallpaper. Status code: ${downloadResult.response.statusCode}",
            );
          }
        }
      } else {
        _updateStatus("Downloading wallpaper from $_activeTab repository...");
        downloadResult = await _githubService.downloadWallpaper(
          repoUrlToUse,
          day,
          resolution,
          '', // Extension is not needed for other tabs
        );

        if (downloadResult.response.statusCode == 200) {
          downloadedFileName = downloadResult.fileName;
          savedFile = await _cacheService.saveFile(
            downloadedFileName,
            downloadResult.response.bodyBytes,
          );
        } else {
          throw Exception(
            "Failed to download wallpaper from $_activeTab repository. Status code: ${downloadResult.response.statusCode}",
          );
        }
      }

      if (savedFile != null && downloadedFileName != null) {
        _wallpaperService.setWallpaper(savedFile.path);
        _updateStatus(
          "Success! Wallpaper updated: $downloadedFileName.",
          file: savedFile,
        );
      } else {
        throw Exception("Wallpaper not found or could not be downloaded.");
      }
    } catch (e) {
      _updateStatus("Error: ${e.toString()}");
    }
  }

  void _updateStatus(String message, {File? file}) {
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    _status = "[$timestamp] $message";
    if (file != null) {
      _currentWallpaperFile = file;
    }
    // print(_status); // For debugging
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
