import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:http/http.dart' as http;
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

  File? _currentWallpaperFile;
  File? get currentWallpaperFile => _currentWallpaperFile;

  bool _autostartEnabled = true;
  bool get autostartEnabled => _autostartEnabled;

  String _currentResolution = '1920x1080'; // Default value
  String get currentResolution => _currentResolution;

  Timer? _timer;

  AppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    _repoUrl = await _settingsService.getRepoUrl();
    _autostartEnabled = await _settingsService.isAutostartEnabled();
    _currentResolution = await _settingsService.getResolution();
    updateAutostart();
    await updateWallpaper(isManual: false);
    _startScheduler();
    notifyListeners();
  }

  void _startScheduler() {
    // Cancel any existing timer
    _timer?.cancel();
    // Check every hour
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      print("Scheduler check running...");
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

  Future<void> toggleAutostart(bool enabled) async {
    _autostartEnabled = enabled;
    await _settingsService.setAutostart(enabled);
    updateAutostart();
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
      http.Response? response;
      String? foundExtension;

      for (final ext in supportedImageExtensions) {
        final fileNameWithExt = '$day$resolution$ext';
        final localFile = await _cacheService.getLocalFile(fileNameWithExt);

        if (!isManual && await localFile.exists()) {
          _updateStatus(
            "Today's wallpaper is already set. Next check scheduled.",
            file: localFile,
          );
          return;
        }

        _updateStatus("Downloading wallpaper for $day ($resolution)$ext...");
        response = await _githubService.downloadWallpaper(
          _repoUrl,
          day,
          resolution,
          ext, // Pass the extension
        );

        if (response.statusCode == 200) {
          savedFile = await _cacheService.saveFile(
            fileNameWithExt,
            response.bodyBytes,
          );
          foundExtension = ext;
          break; // Found and downloaded, exit loop
        } else if (response.statusCode != 404) {
          // If it's not a 404, it's a general error, throw it
          throw Exception(
            "Failed to download wallpaper. Status code: ${response.statusCode}",
          );
        }
        // If 404, continue to next extension
      }

      if (savedFile != null && foundExtension != null) {
        _wallpaperService.setWallpaper(savedFile.path);
        _updateStatus(
          "Success! Wallpaper updated for $day ($resolution)$foundExtension.",
          file: savedFile,
        );
      } else {
        throw Exception(
          "Wallpaper for $day$resolution not found in the repository with any supported extension.",
        );
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
    print(_status); // For debugging
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
