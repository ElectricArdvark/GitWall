import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/services/settings_service.dart';
import 'package:gitwall/services/startup_service.dart';
import 'package:gitwall/services/banned_wallpapers_service.dart';
import 'package:gitwall/services/favourite_wallpapers_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import '../constants.dart'; // Import constants.dart
import '../services/github_service.dart';
import '../services/wallpaper_service.dart';
import '../utils/helpers.dart';

class AppState extends ChangeNotifier {
  // Services
  final GitHubService _githubService = GitHubService();
  GitHubService get githubService => _githubService;
  final WallpaperService _wallpaperService = WallpaperService();
  WallpaperService get wallpaperService => _wallpaperService;
  final SettingsService _settingsService = SettingsService();
  final StartupService _startupService = StartupService();
  late final BannedWallpapersService _bannedWallpapersService;
  BannedWallpapersService get bannedWallpapersService =>
      _bannedWallpapersService;
  late final FavouriteWallpapersService _favouriteWallpapersService;
  FavouriteWallpapersService get favouriteWallpapersService =>
      _favouriteWallpapersService;

  // Custom cache manager for wallpapers
  late BaseCacheManager _customCacheManager;

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

  String _githubToken = "";
  String get githubToken => _githubToken;

  bool _autoShuffleEnabled = true;
  bool get autoShuffleEnabled => _autoShuffleEnabled;

  bool _useOnlyFavouritesEnabled = false;
  bool get useOnlyFavouritesEnabled => _useOnlyFavouritesEnabled;

  bool _closeToTrayEnabled = true;
  bool get closeToTrayEnabled => _closeToTrayEnabled;

  bool _startMinimizedEnabled = false;
  bool get startMinimizedEnabled => _startMinimizedEnabled;

  Timer? _timer;

  // Used wallpapers for cycling, key is tab, value is list of uniqueIds
  Map<String, List<String>> _usedWallpapers = {};

  // Banned wallpapers for each tab, key is tab, value is list of maps with uniqueId and url
  Map<String, List<Map<String, String>>> _bannedWallpapers = {};

  // Public getter for banned wallpapers
  Map<String, List<Map<String, String>>> get bannedWallpapers =>
      _bannedWallpapers;

  // Favourite wallpapers for each tab, key is tab, value is list of maps with uniqueId and url
  Map<String, List<Map<String, String>>> _favouriteWallpapers = {};

  // Public getter for favourite wallpapers
  Map<String, List<Map<String, String>>> get favouriteWallpapers =>
      _favouriteWallpapers;

  bool _bannedWallpapersChanged = false;
  bool get bannedWallpapersChanged => _bannedWallpapersChanged;

  void resetBannedWallpapersChanged() {
    _bannedWallpapersChanged = false;
  }

  // Cached URLs for each tab to avoid repeated API calls
  Map<String, List<String>> _cachedUrls = {};

  AppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize services
    _bannedWallpapersService = BannedWallpapersService(_settingsService);
    _favouriteWallpapersService = FavouriteWallpapersService(_settingsService);

    // Initialize custom cache manager
    final tempPath = Platform.environment['TEMP'];
    final cacheDir = Directory('$tempPath\\gitwall_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _customCacheManager = CacheManager(
      Config(
        'gitwall_cache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 1000,
        repo: JsonCacheInfoRepository(databaseName: 'gitwall_cache'),
        fileService: HttpFileService(),
      ),
    );

    _repoUrl = await _settingsService.getRepoUrl();
    _customRepoUrl = await _settingsService.getCustomRepoUrl();
    _activeTab = await _settingsService.getActiveTab();
    _autostartEnabled = await _settingsService.isAutostartEnabled();
    _currentResolution = await _settingsService.getResolution();
    _wallpaperIntervalMinutes = await _settingsService.getWallpaperInterval();
    _hideStatus = await _settingsService.getHideStatus();
    _customWallpaperLocation =
        await _settingsService.getCustomWallpaperLocation();
    _githubToken = await _settingsService.getGithubToken();
    _autoShuffleEnabled = await _settingsService.getAutoShuffle();
    _useOnlyFavouritesEnabled = await _settingsService.getUseOnlyFavourites();
    _closeToTrayEnabled = await _settingsService.isCloseToTrayEnabled();
    _startMinimizedEnabled = await _settingsService.isStartMinimizedEnabled();
    _usedWallpapers = await _settingsService.getUsedWallpapers();
    _bannedWallpapers = await _bannedWallpapersService.getBannedWallpapers();
    _favouriteWallpapers =
        await _favouriteWallpapersService.getFavouriteWallpapers();

    // Load the last weekly wallpaper path
    final lastWeeklyPath =
        await _settingsService.getCurrentWeeklyWallpaperPath();
    if (lastWeeklyPath != null) {
      final lastWeeklyFile = File(lastWeeklyPath);
      if (await lastWeeklyFile.exists()) {
        _currentWallpaperFile = lastWeeklyFile;
      }
    }

    _githubService.setToken(_githubToken);
    _githubService.setCacheManager(_customCacheManager);
    updateAutostart();
    await updateWallpaper(isManual: false);
    _startScheduler();
    notifyListeners();
  }

  void _startScheduler() {
    _timer?.cancel();
    // Don't start timer for Weekly tab - shuffling should be off always
    if (_autoShuffleEnabled && _activeTab != 'Weekly') {
      _timer = Timer.periodic(Duration(minutes: _wallpaperIntervalMinutes), (
        Timer timer,
      ) {
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
    // Clear cached URLs when repository changes
    _cachedUrls.remove('Custom');
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
      await updateWallpaper(isManual: false);
    }
    // Restart scheduler when tab changes to handle Weekly tab shuffling
    _startScheduler();
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

  Future<void> toggleUseOnlyFavourites(bool enabled) async {
    _useOnlyFavouritesEnabled = enabled;
    await _settingsService.setUseOnlyFavourites(enabled);
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

  /// Public method to check internet availability
  Future<bool> isInternetAvailable() async {
    return await _isInternetAvailable();
  }

  Future<void> updateWallpaper({
    bool isManual = false,
    bool fromTimer = false,
  }) async {
    if (isManual) {
      _updateStatus("Force refresh initiated...");
      // On force refresh, don't change the wallpaper - just refresh the current one
      if (_currentWallpaperFile != null &&
          _currentWallpaperFile!.existsSync()) {
        _wallpaperService.setWallpaper(_currentWallpaperFile!.path);
        _updateStatus(
          "Wallpaper refreshed (no change).",
          file: _currentWallpaperFile,
        );
        return;
      }
      // Clear cached URLs on manual refresh to ensure banned wallpapers are filtered out
      _cachedUrls.remove(_activeTab);
    } else if (fromTimer &&
        (_activeTab == 'Multi' || _activeTab == 'Custom') &&
        !_autoShuffleEnabled) {
      // Skip auto-update for Multi and Custom tabs from timer unless auto shuffle is enabled
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
        case 'Saved':
          // For Saved tab, use cached wallpapers instead of downloading
          await _setRandomCachedWallpaper();
          return;
        default:
          repoUrlToUse = defaultRepoUrl;
      }

      if (repoUrlToUse.isEmpty) {
        _updateStatus("Custom repository URL is not set.");
        return;
      }

      final bool isInternetAvailable = await _isInternetAvailable();

      if (!isInternetAvailable) {
        _updateStatus(
          "No internet connection detected. Cannot download wallpaper.",
        );
        return;
      }

      // Wallpaper source parameters are handled individually for each tab

      if (_activeTab == 'Weekly') {
        // For weekly, try to build the expected filename
        for (final ext in supportedImageExtensions) {
          final candidateFileName = '${day}_$resolution$ext';

          _updateStatus("Downloading wallpaper for $day ($resolution)$ext...");
          try {
            downloadResult = await _githubService.downloadWallpaper(
              repoUrlToUse,
              day,
              resolution,
              ext,
            );

            savedFile = downloadResult.file;
            downloadedFileName = downloadResult.fileName;

            // Add this wallpaper to the used list for the current tab
            if (_activeTab == 'Multi' || _activeTab == 'Custom') {
              final used = _usedWallpapers[_activeTab] ?? [];
              final uniqueId = _generateWallpaperUniqueId(
                repoUrlToUse,
                day,
                resolution,
                candidateFileName,
              );
              if (!used.contains(uniqueId)) {
                used.add(uniqueId);
                _usedWallpapers[_activeTab] = used;
                // Save immediately to ensure persistence
                _settingsService.saveUsedWallpapers(_usedWallpapers);
              }
            }
            break;
          } catch (e) {
            // Continue to next extension if this one fails
            continue;
          }
        }
      } else {
        // For Multi and Custom repositories
        _updateStatus("Downloading wallpaper...");

        if (_autoShuffleEnabled) {
          // Cycling logic
          // Use cached URLs if available and not forcing refresh, otherwise fetch new ones
          List<String> urls;
          if (isManual ||
              !_cachedUrls.containsKey(_activeTab) ||
              _cachedUrls[_activeTab]!.isEmpty) {
            // Fetch URLs only on manual refresh or app start
            urls = await _githubService.getImageUrls(
              repoUrlToUse,
              resolution,
              effectiveDay,
              100,
            ); // get all
            _cachedUrls[_activeTab] = urls;
          } else {
            // Use cached URLs for timer-based updates
            urls = _cachedUrls[_activeTab]!;
          }

          // If use only favourites is enabled, filter URLs to only include favourited ones
          if (_useOnlyFavouritesEnabled) {
            final tabKey =
                (_activeTab == 'Multi' || _activeTab == 'Custom')
                    ? 'Multi'
                    : _activeTab;
            final favourites = _favouriteWallpapers[tabKey] ?? [];
            final favouriteUrls = favourites.map((f) => f['url']!).toSet();
            urls = urls.where((url) => favouriteUrls.contains(url)).toList();
          }

          final sortedUrls = urls..sort();
          final used = _usedWallpapers[_activeTab] ?? [];
          String? nextUrl;
          for (final url in sortedUrls) {
            final uri = Uri.parse(url);
            final fileName = uri.pathSegments.last;
            final uniqueId = _generateWallpaperUniqueId(
              repoUrlToUse,
              effectiveDay,
              resolution,
              fileName,
            );
            if (!used.contains(uniqueId)) {
              nextUrl = url;
              used.add(uniqueId);
              break;
            }
          }
          if (nextUrl == null && sortedUrls.isNotEmpty) {
            // All used, reset
            used.clear();
            nextUrl = sortedUrls.first;
            final uri = Uri.parse(nextUrl);
            final fileName = uri.pathSegments.last;
            final uniqueId = _generateWallpaperUniqueId(
              repoUrlToUse,
              effectiveDay,
              resolution,
              fileName,
            );
            used.add(uniqueId);
          }
          _usedWallpapers[_activeTab] = used;
          // Save immediately to ensure persistence
          _settingsService.saveUsedWallpapers(_usedWallpapers);
          if (nextUrl != null) {
            await setWallpaperForUrl(nextUrl);
            return;
          }
        } else {
          // Original random logic
          _updateStatus("Downloading wallpaper from $_activeTab repository...");
          downloadResult = await _githubService.downloadWallpaper(
            repoUrlToUse,
            effectiveDay,
            resolution,
            '', // Extension is not needed for other tabs
          );

          savedFile = downloadResult.file;
          downloadedFileName = downloadResult.fileName;
        }
      }

      if (savedFile != null && downloadedFileName != null) {
        _wallpaperService.setWallpaper(savedFile.path);
        _updateStatus(
          "Success! Wallpaper downloaded: $downloadedFileName.",
          file: savedFile,
        );
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

  /// Public method to generate wallpaper unique ID
  String generateWallpaperUniqueId(
    String repoUrl,
    String day,
    String resolution,
    String fileName,
  ) {
    return _generateWallpaperUniqueId(repoUrl, day, resolution, fileName);
  }

  void _updateStatus(String message, {File? file}) {
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    _status = "[$timestamp] $message";
    if (file != null) {
      _currentWallpaperFile = file;
      // Save the current weekly wallpaper path for offline preview
      if (_activeTab == 'Weekly') {
        _settingsService.saveCurrentWeeklyWallpaperPath(file.path);
      }
    }
    notifyListeners();
  }

  /// Downloads and sets wallpaper from a given URL
  Future<void> setWallpaperForUrl(String url) async {
    _updateStatus("Downloading wallpaper from URL...");

    try {
      final file = await _customCacheManager.getSingleFile(url);
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

      _wallpaperService.setWallpaper(file.path);
      _updateStatus("Wallpaper set from URL: $fileName", file: file);
      // Save the current weekly wallpaper path for offline preview
      if (_activeTab == 'Weekly') {
        _settingsService.saveCurrentWeeklyWallpaperPath(file.path);
      }

      // Add this wallpaper to the used list for the current tab
      if (_activeTab == 'Multi' || _activeTab == 'Custom') {
        final used = _usedWallpapers[_activeTab] ?? [];
        if (!used.contains(uniqueId)) {
          used.add(uniqueId);
          _usedWallpapers[_activeTab] = used;
          // Save immediately to ensure persistence
          _settingsService.saveUsedWallpapers(_usedWallpapers);
        }
      }
    } catch (e) {
      _updateStatus("Error setting wallpaper: ${e.toString()}");
    }
  }

  /// Sets the next wallpaper in the cycle for Multi, Custom, and Saved tabs
  Future<void> setNextWallpaper() async {
    if (_activeTab != 'Multi' &&
        _activeTab != 'Custom' &&
        _activeTab != 'Saved') {
      _updateStatus(
        "Next wallpaper only available for Multi, Custom, and Saved tabs",
      );
      return;
    }

    _updateStatus("Setting next wallpaper...");

    try {
      final resolution = await _settingsService.getResolution();
      String repoUrlToUse;
      String effectiveDay = '';

      switch (_activeTab) {
        case 'Multi':
          repoUrlToUse = defaultRepoUrl;
          effectiveDay = 'multi';
          break;
        case 'Custom':
          repoUrlToUse = _customRepoUrl;
          if (repoUrlToUse.isEmpty) {
            _updateStatus("Custom repository URL is not set.");
            return;
          }
          break;
        case 'Saved':
          // For Saved tab, we cycle through cached images
          await _setNextCachedWallpaper();
          return;
        default:
          return;
      }

      // Use cached URLs if available, otherwise fetch new ones
      List<String> urls;
      if (!_cachedUrls.containsKey(_activeTab) ||
          _cachedUrls[_activeTab]!.isEmpty) {
        urls = await _githubService.getImageUrls(
          repoUrlToUse,
          resolution,
          effectiveDay,
          100,
        );
        _cachedUrls[_activeTab] = urls;
      } else {
        urls = _cachedUrls[_activeTab]!;
      }

      // If use only favourites is enabled, filter URLs to only include favourited ones
      if (_useOnlyFavouritesEnabled) {
        final tabKey =
            (_activeTab == 'Multi' || _activeTab == 'Custom')
                ? 'Multi'
                : _activeTab;
        final favourites = _favouriteWallpapers[tabKey] ?? [];
        final favouriteUrls = favourites.map((f) => f['url']!).toSet();
        urls = urls.where((url) => favouriteUrls.contains(url)).toList();
      }

      final sortedUrls = urls..sort();
      final used = _usedWallpapers[_activeTab] ?? [];
      final banned = _bannedWallpapers[_activeTab] ?? [];
      String? nextUrl;

      // Find the next unused and unbanned wallpaper
      for (final url in sortedUrls) {
        final uri = Uri.parse(url);
        final fileName = uri.pathSegments.last;
        final uniqueId = _generateWallpaperUniqueId(
          repoUrlToUse,
          effectiveDay,
          resolution,
          fileName,
        );
        final isBanned = banned.any((entry) => entry['uniqueId'] == uniqueId);
        if (!used.contains(uniqueId) && !isBanned) {
          nextUrl = url;
          used.add(uniqueId);
          break;
        }
      }

      // If no unused wallpaper found, reset the cycle but skip banned ones
      if (nextUrl == null && sortedUrls.isNotEmpty) {
        used.clear();
        for (final url in sortedUrls) {
          final uri = Uri.parse(url);
          final fileName = uri.pathSegments.last;
          final uniqueId = _generateWallpaperUniqueId(
            repoUrlToUse,
            effectiveDay,
            resolution,
            fileName,
          );
          final isBanned = banned.any((entry) => entry['uniqueId'] == uniqueId);
          if (!isBanned) {
            nextUrl = url;
            used.add(uniqueId);
            break;
          }
        }
      }

      _usedWallpapers[_activeTab] = used;
      await _settingsService.saveUsedWallpapers(_usedWallpapers);

      if (nextUrl != null) {
        await setWallpaperForUrl(nextUrl);
      } else {
        _updateStatus("No wallpapers available");
      }
    } catch (e) {
      _updateStatus("Error setting next wallpaper: ${e.toString()}");
    }
  }

  /// Bans a wallpaper by URL for the current tab
  Future<void> banWallpaper(String url) async {
    if (_activeTab != 'Multi' && _activeTab != 'Custom') {
      _updateStatus("Ban wallpaper only available for Multi and Custom tabs");
      return;
    }

    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      final resolution = _currentResolution;
      String repoUrlToUse;
      String effectiveDay = '';

      switch (_activeTab) {
        case 'Multi':
          repoUrlToUse = defaultRepoUrl;
          effectiveDay = 'multi';
          break;
        case 'Custom':
          repoUrlToUse = _customRepoUrl;
          break;
        default:
          return;
      }

      final uniqueId = _generateWallpaperUniqueId(
        repoUrlToUse,
        effectiveDay,
        resolution,
        fileName,
      );

      // Use 'Multi' key for both Multi and Custom tabs to share banned wallpapers
      final tabKey =
          (_activeTab == 'Multi' || _activeTab == 'Custom')
              ? 'Multi'
              : _activeTab;

      // Check if already banned
      if (!_bannedWallpapersService.isWallpaperBanned(
        _bannedWallpapers,
        tabKey,
        uniqueId,
      )) {
        _bannedWallpapers = await _bannedWallpapersService.banWallpaper(
          _bannedWallpapers,
          tabKey,
          uniqueId,
          url,
        );

        // Also remove from used list if it was there
        final used = _usedWallpapers[_activeTab] ?? [];
        used.remove(uniqueId);
        _usedWallpapers[_activeTab] = used;
        await _settingsService.saveUsedWallpapers(_usedWallpapers);

        _updateStatus("Wallpaper banned and hidden from previews");
        _bannedWallpapersChanged = true;
        notifyListeners();
      } else {
        _updateStatus("Wallpaper is already banned");
      }
    } catch (e) {
      _updateStatus("Error banning wallpaper: ${e.toString()}");
    }
  }

  /// Unbans a wallpaper by unique ID for the current tab
  Future<void> unbanWallpaper(String uniqueId) async {
    try {
      // Check all tabs to find where this wallpaper is banned
      String? tabKeyToUnban;
      for (final entry in _bannedWallpapers.entries) {
        final bannedInTab = entry.value;
        if (bannedInTab.any((banned) => banned['uniqueId'] == uniqueId)) {
          tabKeyToUnban = entry.key;
          break;
        }
      }

      if (tabKeyToUnban == null) {
        _updateStatus("Wallpaper is not currently banned");
        return;
      }

      _bannedWallpapers = await _bannedWallpapersService.unbanWallpaper(
        _bannedWallpapers,
        tabKeyToUnban,
        uniqueId,
      );

      _updateStatus(
        "Wallpaper unbanned from $tabKeyToUnban tab and will appear in all previews",
      );
      _bannedWallpapersChanged = true;
      notifyListeners();
    } catch (e) {
      _updateStatus("Error unbanning wallpaper: ${e.toString()}");
    }
  }

  Future<void> saveStateBeforeClose() async {
    await _settingsService.saveUsedWallpapers(_usedWallpapers);
    await _bannedWallpapersService.saveBannedWallpapers(_bannedWallpapers);
    await _favouriteWallpapersService.saveFavouriteWallpapers(
      _favouriteWallpapers,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Note: dispose() is synchronous, so we can't await here
    // The save operation should be handled in saveStateBeforeClose() instead
    super.dispose();
  }

  /// Favourites a wallpaper by URL for the current tab
  Future<void> favouriteWallpaper(String url) async {
    if (_activeTab != 'Multi' && _activeTab != 'Custom') {
      _updateStatus(
        "Favourite wallpaper only available for Multi and Custom tabs",
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      final resolution = _currentResolution;
      String repoUrlToUse;
      String effectiveDay = '';

      switch (_activeTab) {
        case 'Multi':
          repoUrlToUse = defaultRepoUrl;
          effectiveDay = 'multi';
          break;
        case 'Custom':
          repoUrlToUse = _customRepoUrl;
          break;
        default:
          return;
      }

      final uniqueId = _generateWallpaperUniqueId(
        repoUrlToUse,
        effectiveDay,
        resolution,
        fileName,
      );

      // Use 'Multi' key for both Multi and Custom tabs to share favourite wallpapers
      final tabKey =
          (_activeTab == 'Multi' || _activeTab == 'Custom')
              ? 'Multi'
              : _activeTab;

      // Check if already favourited
      if (!_favouriteWallpapersService.isWallpaperFavourited(
        _favouriteWallpapers,
        tabKey,
        uniqueId,
      )) {
        // Cache the wallpaper to ensure it's available offline
        try {
          await _customCacheManager.getSingleFile(url);
          _updateStatus("Wallpaper cached and added to favourites");
        } catch (cacheError) {
          _updateStatus(
            "Warning: Failed to cache wallpaper, but added to favourites",
          );
          print('Error caching favourited wallpaper: $cacheError');
        }

        _favouriteWallpapers = await _favouriteWallpapersService
            .favouriteWallpaper(_favouriteWallpapers, tabKey, uniqueId, url);

        _updateStatus("Wallpaper added to favourites");
        notifyListeners();
      } else {
        _updateStatus("Wallpaper is already in favourites");
      }
    } catch (e) {
      _updateStatus("Error favouriting wallpaper: ${e.toString()}");
    }
  }

  /// Unfavourites a wallpaper by unique ID for the current tab
  Future<void> unfavouriteWallpaper(String uniqueId) async {
    if (_activeTab != 'Multi' && _activeTab != 'Custom') {
      _updateStatus(
        "Unfavourite wallpaper only available for Multi and Custom tabs",
      );
      return;
    }

    try {
      // Use 'Multi' key for both Multi and Custom tabs to share favourite wallpapers
      final tabKey =
          (_activeTab == 'Multi' || _activeTab == 'Custom')
              ? 'Multi'
              : _activeTab;

      _favouriteWallpapers = await _favouriteWallpapersService
          .unfavouriteWallpaper(_favouriteWallpapers, tabKey, uniqueId);

      _updateStatus("Wallpaper removed from favourites");
      notifyListeners();
    } catch (e) {
      _updateStatus("Error unfavouriting wallpaper: ${e.toString()}");
    }
  }

  /// Sets a random cached wallpaper for the Saved tab (used for auto-shuffle)
  Future<void> _setRandomCachedWallpaper() async {
    try {
      // Get the cache directory
      final tempPath = Platform.environment['TEMP'];
      final cacheDir = Directory('$tempPath\\gitwall_cache');

      // Create directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Get all cached image files
      final files =
          cacheDir.listSync().where((file) => file is File).cast<File>();
      final imageFiles =
          files.where((file) {
            final extension = file.path.split('.').last.toLowerCase();
            return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
          }).toList();

      if (imageFiles.isEmpty) {
        _updateStatus("No cached wallpapers found");
        return;
      }

      // Randomly select a cached wallpaper
      imageFiles.shuffle(); // Shuffle the list randomly
      final randomFile = imageFiles.first;

      _wallpaperService.setWallpaper(randomFile.path);
      final fileName = randomFile.path.split(Platform.pathSeparator).last;
      _updateStatus("Set random cached wallpaper: $fileName", file: randomFile);
    } catch (e) {
      _updateStatus("Error setting random cached wallpaper: ${e.toString()}");
    }
  }

  /// Sets the next cached wallpaper for the Saved tab
  Future<void> _setNextCachedWallpaper() async {
    try {
      // Get the cache directory
      final tempPath = Platform.environment['TEMP'];
      final cacheDir = Directory('$tempPath\\gitwall_cache');

      // Create directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Get all cached image files
      final files =
          cacheDir.listSync().where((file) => file is File).cast<File>();
      final imageFiles =
          files.where((file) {
            final extension = file.path.split('.').last.toLowerCase();
            return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
          }).toList();

      if (imageFiles.isEmpty) {
        _updateStatus("No cached wallpapers found");
        return;
      }

      // Sort files by name for consistent cycling
      imageFiles.sort((a, b) => a.path.compareTo(b.path));

      // Get used wallpapers for Saved tab
      final used = _usedWallpapers['Saved'] ?? [];
      File? nextFile;

      // Find the next unused cached wallpaper
      for (final file in imageFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final uniqueId = _generateWallpaperUniqueId(
          'cached', // Use 'cached' as repo identifier
          'saved',
          _currentResolution,
          fileName,
        );

        if (!used.contains(uniqueId)) {
          nextFile = file;
          used.add(uniqueId);
          break;
        }
      }

      // If no unused wallpaper found, reset the cycle
      if (nextFile == null && imageFiles.isNotEmpty) {
        used.clear();
        nextFile = imageFiles.first;
        final fileName = nextFile.path.split(Platform.pathSeparator).last;
        final uniqueId = _generateWallpaperUniqueId(
          'cached',
          'saved',
          _currentResolution,
          fileName,
        );
        used.add(uniqueId);
      }

      _usedWallpapers['Saved'] = used;
      await _settingsService.saveUsedWallpapers(_usedWallpapers);

      if (nextFile != null) {
        _wallpaperService.setWallpaper(nextFile.path);
        final fileName = nextFile.path.split(Platform.pathSeparator).last;
        _updateStatus("Set cached wallpaper: $fileName", file: nextFile);
      } else {
        _updateStatus("No cached wallpapers available");
      }
    } catch (e) {
      _updateStatus("Error setting next cached wallpaper: ${e.toString()}");
    }
  }
}
