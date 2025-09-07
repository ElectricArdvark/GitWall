import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/services/settings_service.dart';
import 'package:gitwall/services/startup_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants.dart'; // Import constants.dart
import '../services/cache_service.dart';
import '../services/github_service.dart';
import '../services/wallpaper_service.dart';
import '../utils/helpers.dart';

class AppState extends ChangeNotifier {
  // Services
  final GitHubService _githubService = GitHubService();
  GitHubService get githubService => _githubService;
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

  bool _hideStatus = false; // Default to show status
  bool get hideStatus => _hideStatus;

  String? _customWallpaperLocation;
  String? get customWallpaperLocation => _customWallpaperLocation;

  bool _useCachedWhenNoInternet = true;
  bool get useCachedWhenNoInternet => _useCachedWhenNoInternet;

  String _githubToken = "";
  String get githubToken => _githubToken;

  bool _autoShuffleEnabled = true;
  bool get autoShuffleEnabled => _autoShuffleEnabled;

  bool _closeToTrayEnabled = true;
  bool get closeToTrayEnabled => _closeToTrayEnabled;

  bool _startMinimizedEnabled = false;
  bool get startMinimizedEnabled => _startMinimizedEnabled;

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
    _hideStatus = await _settingsService.getHideStatus();
    _customWallpaperLocation =
        await _settingsService.getCustomWallpaperLocation();
    _useCachedWhenNoInternet =
        await _settingsService.getUseCachedWhenNoInternet();
    _githubToken = await _settingsService.getGithubToken();
    _autoShuffleEnabled = await _settingsService.getAutoShuffle();
    _closeToTrayEnabled = await _settingsService.isCloseToTrayEnabled();
    _startMinimizedEnabled = await _settingsService.isStartMinimizedEnabled();
    _githubService.setToken(_githubToken);
    // Initialize cache service with custom wallpaper location
    _cacheService.setCustomWallpaperLocation(_customWallpaperLocation);
    // No need to load welcome state from persistence anymore
    updateAutostart();
    await updateWallpaper(isManual: false);
    _startScheduler();
    notifyListeners();
  }

  void _startScheduler() {
    // Cancel any existing timer
    _timer?.cancel();
    // Only start timer if auto shuffle is enabled and we're on weekly tab
    if (_autoShuffleEnabled) {
      _timer = Timer.periodic(Duration(minutes: _wallpaperIntervalMinutes), (
        Timer timer,
      ) {
        // print(
        //   "Scheduler check running (interval: $_wallpaperIntervalMinutes minutes)...",
        // );
        updateWallpaper(isManual: false, fromTimer: true);
      });
    }
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
    if (_activeTab == 'Weekly') {
      await updateWallpaper(isManual: true);
    }
  }

  Future<void> toggleAutostart(bool enabled) async {
    _autostartEnabled = enabled;
    await _settingsService.setAutostart(enabled);
    updateAutostart();
    notifyListeners();
  }

  Future<void> toggleHideStatus(bool enabled) async {
    _hideStatus = enabled;
    await _settingsService.setHideStatus(enabled);
    notifyListeners();
  }

  Future<void> toggleUseCachedWhenNoInternet(bool enabled) async {
    _useCachedWhenNoInternet = enabled;
    await _settingsService.setUseCachedWhenNoInternet(enabled);
    notifyListeners();
  }

  Future<void> toggleCloseToTray(bool enabled) async {
    _closeToTrayEnabled = enabled;
    await _settingsService.setCloseToTray(enabled);
    notifyListeners();
  }

  Future<void> toggleStartMinimized(bool enabled) async {
    _startMinimizedEnabled = enabled;
    await _settingsService.setStartMinimized(enabled);
    notifyListeners();
  }

  Future<void> toggleAutoShuffle(bool enabled) async {
    _autoShuffleEnabled = enabled;
    await _settingsService.setAutoShuffle(enabled);
    _startScheduler();
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

  void setShowWelcomeInRightSide(bool show) {
    _showWelcomeInRightSide = show;
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

  Future<void> setCustomWallpaperLocation(String? location) async {
    _customWallpaperLocation = location;
    if (location != null) {
      await _settingsService.saveCustomWallpaperLocation(location);
    } else {
      // Clear the setting by setting empty string
      await _settingsService.saveCustomWallpaperLocation('');
      _customWallpaperLocation = null;
    }
    // Update cache service with the new location
    _cacheService.setCustomWallpaperLocation(_customWallpaperLocation);
    notifyListeners();
  }

  Future<void> setGithubToken(String token) async {
    _githubToken = token;
    await _settingsService.saveGithubToken(token);
    _githubService.setToken(token);
    notifyListeners();
  }

  Future<String> getGithubToken() async {
    _githubToken = await _settingsService.getGithubToken();
    return _githubToken;
  }

  Future<bool> _isInternetAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('http://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateWallpaper({
    bool isManual = false,
    bool fromTimer = false,
  }) async {
    if (isManual) {
      _updateStatus(
        "Force refresh initiated - checking for cached wallpaper...",
      );
    } else if (fromTimer && (_activeTab == 'Multi' || _activeTab == 'Custom')) {
      // Skip auto-update for Multi and Custom tabs from timer
      _updateStatus("Skipping auto-update for $_activeTab tab");
      return;
    } else {
      _updateStatus("Checking for new wallpaper...");
    }

    try {
      final day = getCurrentDay();
      final resolution = await _settingsService.getResolution();

      File? savedFile;
      late WallpaperDownloadResult
      downloadResult; // Changed to late and non-nullable
      String? downloadedFileName;

      String repoUrlToUse;
      String effectiveDay = day;
      switch (_activeTab) {
        case 'Weekly':
          repoUrlToUse = defaultRepoUrl;
          break;
        case 'Multi':
          repoUrlToUse = defaultRepoUrl;
          effectiveDay = 'multi';
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

      final bool isInternetAvailable = await _isInternetAvailable();

      if (!isInternetAvailable) {
        _updateStatus("No internet connection detected.");
      }

      // Wallpaper source parameters are handled individually for each tab

      if (_activeTab == 'Weekly') {
        // For weekly, try to build the expected filename

        if (!isInternetAvailable && _useCachedWhenNoInternet) {
          for (final ext in supportedImageExtensions) {
            final candidateFileName = '${day}_$resolution$ext';
            final candidateUniqueId = _generateWallpaperUniqueId(
              repoUrlToUse,
              day,
              resolution,
              candidateFileName,
            );
            if (await _cacheService.isWallpaperCached(candidateUniqueId)) {
              final cachedFile = await _cacheService.getCachedWallpaper(
                candidateUniqueId,
              );
              if (cachedFile != null) {
                _wallpaperService.setWallpaper(cachedFile.path);
                _updateStatus(
                  "Using cached image due to no internet: $candidateFileName.",
                  file: cachedFile,
                );
                return;
              }
            }
          }
          // If no matching cache, use most recent
          final mostRecent = await _cacheService.getMostRecentCachedWallpaper();
          if (mostRecent != null) {
            _wallpaperService.setWallpaper(mostRecent.path);
            _updateStatus(
              "Using cached image due to no internet.",
              file: mostRecent,
            );
            return;
          }
          throw Exception("No cached wallpaper available and no internet.");
        }

        for (final ext in supportedImageExtensions) {
          final candidateFileName = '${day}_$resolution$ext';
          final candidateUniqueId = _generateWallpaperUniqueId(
            repoUrlToUse,
            day,
            resolution,
            candidateFileName,
          );

          // Check if already cached
          if (await _cacheService.isWallpaperCached(candidateUniqueId)) {
            final cachedFile = await _cacheService.getCachedWallpaper(
              candidateUniqueId,
            );
            if (cachedFile != null) {
              _wallpaperService.setWallpaper(cachedFile.path);
              _updateStatus(
                "Wallpaper is already cached: $candidateFileName.",
                file: cachedFile,
              );
              return;
            }
          }

          _updateStatus("Downloading wallpaper for $day ($resolution)$ext...");
          try {
            downloadResult = await _githubService.downloadWallpaper(
              repoUrlToUse,
              day,
              resolution,
              ext,
            );

            if (downloadResult.response.statusCode == 200) {
              // Save with unique ID
              savedFile = await _cacheService.saveWallpaperWithId(
                downloadResult.uniqueId,
                downloadResult.fileName,
                downloadResult.response.bodyBytes,
              );
              downloadedFileName = downloadResult.fileName;
              break;
            } else if (downloadResult.response.statusCode != 404) {
              throw Exception(
                "Failed to download wallpaper. Status code: ${downloadResult.response.statusCode}",
              );
            }
          } catch (e) {
            // Continue to next extension if this one fails
            continue;
          }
        }
      } else {
        // For Multi and Custom repositories
        _updateStatus("Checking wallpaper cache...");

        // For Multi, we need to download first to get the filename
        // We'll cache the result after downloading

        if (!isInternetAvailable && _useCachedWhenNoInternet) {
          final cached = await _cacheService.getMostRecentCachedWallpaper();
          if (cached != null) {
            _wallpaperService.setWallpaper(cached.path);
            _updateStatus(
              "Using cached image due to no internet.",
              file: cached,
            );
            return;
          }
          throw Exception("No cached wallpaper available and no internet.");
        }

        _updateStatus("Downloading wallpaper from $_activeTab repository...");
        downloadResult = await _githubService.downloadWallpaper(
          repoUrlToUse,
          effectiveDay,
          resolution,
          '', // Extension is not needed for other tabs
        );

        if (downloadResult.response.statusCode == 200) {
          // Check if already cached
          if (await _cacheService.isWallpaperCached(downloadResult.uniqueId)) {
            final cachedFile = await _cacheService.getCachedWallpaper(
              downloadResult.uniqueId,
            );
            if (cachedFile != null) {
              _wallpaperService.setWallpaper(cachedFile.path);
              _updateStatus(
                "Wallpaper is already cached: ${downloadResult.fileName}.",
                file: cachedFile,
              );
              return;
            }
          }

          // Save with unique ID
          savedFile = await _cacheService.saveWallpaperWithId(
            downloadResult.uniqueId,
            downloadResult.fileName,
            downloadResult.response.bodyBytes,
          );
          downloadedFileName = downloadResult.fileName;
        } else {
          throw Exception(
            "Failed to download wallpaper from $_activeTab repository. Status code: ${downloadResult.response.statusCode}",
          );
        }
      }

      if (savedFile != null && downloadedFileName != null) {
        _wallpaperService.setWallpaper(savedFile.path);
        _updateStatus(
          "Success! Wallpaper downloaded: $downloadedFileName.",
          file: savedFile,
        );

        // Cleanup old cache files
        await _cacheService.cleanupOldCache();
      } else {
        throw Exception("Wallpaper not found or could not be downloaded.");
      }
    } catch (e) {
      _updateStatus("Error: ${e.toString()}");
    }
  }

  /// Generates a unique identifier for a wallpaper based on its source
  String _generateWallpaperUniqueId(
    String repoUrl,
    String day,
    String resolution,
    String fileName,
  ) {
    final sourceKey = '$repoUrl|$day|$resolution|$fileName';
    final hashCode = sourceKey.hashCode.abs();
    return 'wallpaper_${hashCode.toString()}';
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

  /// Downloads and sets wallpaper from a given URL
  Future<void> setWallpaperForUrl(String url) async {
    _updateStatus("Downloading wallpaper from URL...");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final uri = Uri.parse(url);
        final fileName = uri.pathSegments.last;
        final day = ''; // Not applicable
        final resolution = _currentResolution;
        final uniqueId = _generateWallpaperUniqueId(
          '', // repo not needed here
          day,
          resolution,
          fileName,
        );

        final savedFile = await _cacheService.saveWallpaperWithId(
          uniqueId,
          fileName,
          response.bodyBytes,
        );

        _wallpaperService.setWallpaper(savedFile.path);
        _updateStatus("Wallpaper set from URL: $fileName", file: savedFile);
      } else {
        throw Exception("Failed to download: Status ${response.statusCode}");
      }
    } catch (e) {
      _updateStatus("Error setting wallpaper: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
