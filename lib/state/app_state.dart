import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gitwall/services/settings_service.dart';
import 'package:gitwall/services/startup_service.dart';
import 'package:gitwall/buttons/ban_button.dart';
import 'package:gitwall/buttons/favourite_button.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../services/github_service.dart';
import '../services/wallpaper_service.dart';
import '../utils/helpers.dart';
import 'package:path/path.dart' as p;

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

  // Public getter for cache manager
  BaseCacheManager get customCacheManager => _customCacheManager;

  // Helper method to get cache directory path based on custom location setting
  Future<String> getCacheDirectoryPath() async {
    final customLocation = await _settingsService.getCustomWallpaperLocation();
    if (customLocation != null && customLocation.isNotEmpty) {
      return '$customLocation\\GitWall';
    } else {
      final tempPath = Platform.environment['TEMP'];
      return '$tempPath\\gitwall_cache';
    }
  }

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

  bool _closeToTrayEnabled = true;
  bool get closeToTrayEnabled => _closeToTrayEnabled;

  bool _startMinimizedEnabled = false;
  bool get startMinimizedEnabled => _startMinimizedEnabled;

  bool _isDarkTheme = true;
  bool get isDarkTheme => _isDarkTheme;

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
    final directory = await getApplicationSupportDirectory();
    final appDataDir = directory.parent;
    final cachePath = p.join(appDataDir.path, '..', 'GitWall');
    _bannedWallpapersService = BannedWallpapersService();
    _favouriteWallpapersService = FavouriteWallpapersService();

    // Initialize custom cache manager
    final cacheDirPath = await getCacheDirectoryPath();
    final cacheDir = Directory(cacheDirPath);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _customCacheManager = CacheManager(
      Config(
        'gitwall_cache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 1000,
        repo: JsonCacheInfoRepository(
          path: ('$cachePath\\gitwall_cache.json'),
        ), //(databaseName: 'gitwall_cache'),
        fileService: HttpFileService(),
        fileSystem: IOFileSystem(cacheDir.path),
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
    _closeToTrayEnabled = await _settingsService.isCloseToTrayEnabled();
    _startMinimizedEnabled = await _settingsService.isStartMinimizedEnabled();
    _isDarkTheme = await _settingsService.getThemeMode();
    _usedWallpapers = await _settingsService.getUsedWallpapers();
    _bannedWallpapers = await _bannedWallpapersService.getBannedWallpapers();
    _favouriteWallpapers =
        await _favouriteWallpapersService.getFavouriteWallpapers();

    // Auto-select resolution based on screen size if not manually set
    await _autoSelectResolutionIfNeeded();

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
    await _startScheduler();
    notifyListeners();
  }

  Future<void> _startScheduler() async {
    _timer?.cancel();
    final autoShuffleEnabled = await _settingsService.getAutoShuffle();
    // Don't start timer for Weekly tab - shuffling should be off always
    if (autoShuffleEnabled && _activeTab != 'Weekly') {
      _timer = Timer.periodic(Duration(minutes: _wallpaperIntervalMinutes), (
        Timer timer,
      ) {
        updateWallpaper(isManual: false, fromTimer: true);
      });
    }
  }

  Future<void> restartScheduler() async {
    await _startScheduler();
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
    final wasWeekly = _activeTab == 'Weekly';
    _activeTab = tab;
    await _settingsService.saveActiveTab(tab);
    notifyListeners();
    // Restart scheduler when tab changes to handle Weekly tab shuffling
    await _startScheduler();
    // Reset wallpaper when switching to Weekly tab from another tab
    if (tab == 'Weekly' && !wasWeekly) {
      await updateWallpaper(isManual: false);
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

  Future<void> toggleTheme(bool isDark) async {
    _isDarkTheme = isDark;
    await _settingsService.setThemeMode(isDark);
    notifyListeners();
  }

  Future<void> updateWallpaperInterval(int minutes) async {
    _wallpaperIntervalMinutes = minutes;
    await _settingsService.saveWallpaperInterval(minutes);
    await _startScheduler(); // Restart scheduler with new interval
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
    // Mark that user has manually selected resolution (not auto-selected)
    await _settingsService.setResolutionAutoSelected(false);
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
        !await _settingsService.getAutoShuffle()) {
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

        if (await _settingsService.getAutoShuffle()) {
          // Cycling logic
          // Use cached URLs if available and not forcing refresh, otherwise fetch new ones
          List<String> urls;
          if (await _settingsService.getUseOnlyFavourites()) {
            // When using only favourites, fetch from ALL repositories that have favourites
            print(
              'DEBUG: [updateWallpaper FAVOURITES MODE] Fetching URLs from all repositories with favourites...',
            );
            final allUrls = <String>[];

            // Collect all unique repository URLs from favourites
            final repoUrls = <String>{};
            for (final tabFavourites in _favouriteWallpapers.values) {
              for (final favourite in tabFavourites) {
                if (favourite['url'] != null) {
                  final uri = Uri.parse(favourite['url']!);
                  // Extract repo URL from raw GitHub URL
                  final pathSegments = uri.pathSegments;
                  if (pathSegments.length >= 3) {
                    final user = pathSegments[0];
                    final repo = pathSegments[1];
                    final repoUrl = 'https://github.com/$user/$repo';
                    repoUrls.add(repoUrl);
                  }
                }
              }
            }

            print(
              'DEBUG: [updateWallpaper FAVOURITES MODE] Found ${repoUrls.length} repositories with favourites:',
            );
            for (var i = 0; i < repoUrls.length; i++) {
              print(
                'DEBUG: [updateWallpaper FAVOURITES MODE] Repo $i: ${repoUrls.elementAt(i)}',
              );
            }

            // Fetch URLs from each repository - use 'multi' for all to get wallpapers from Multi folder
            for (final repoUrl in repoUrls) {
              try {
                print(
                  'DEBUG: [updateWallpaper FAVOURITES MODE] Fetching from: $repoUrl (using multi folder)',
                );
                final repoWallpaperUrls = await _githubService.getImageUrls(
                  repoUrl,
                  resolution,
                  'multi', // Always use 'multi' to get wallpapers from Multi folder
                  100,
                );
                allUrls.addAll(repoWallpaperUrls);
                print(
                  'DEBUG: [updateWallpaper FAVOURITES MODE] Added ${repoWallpaperUrls.length} URLs from $repoUrl',
                );
              } catch (e) {
                print(
                  'DEBUG: [updateWallpaper FAVOURITES MODE] Error fetching from $repoUrl: $e',
                );
              }
            }

            urls = allUrls;
            print(
              'DEBUG: [updateWallpaper FAVOURITES MODE] Total URLs from all repos: ${urls.length}',
            );
          } else {
            // Normal mode - fetch from current repository only
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
          }

          // If use only favourites is enabled, filter URLs to only include favourited ones from ALL tabs
          if (await _settingsService.getUseOnlyFavourites()) {
            // Collect favourite URLs from all tabs
            final allFavouriteUrls = <String>{};
            for (final tabFavourites in _favouriteWallpapers.values) {
              for (final favourite in tabFavourites) {
                if (favourite['url'] != null) {
                  allFavouriteUrls.add(favourite['url']!);
                }
              }
            }

            print('DEBUG: [updateWallpaper] Favourite URLs collected:');
            for (var i = 0; i < allFavouriteUrls.length; i++) {
              print(
                'DEBUG: [updateWallpaper] Favourite $i: ${allFavouriteUrls.elementAt(i)}',
              );
            }

            print('DEBUG: [updateWallpaper] URLs before favourites filter:');
            for (var i = 0; i < urls.length && i < 10; i++) {
              print('DEBUG: [updateWallpaper] URL $i: ${urls[i]}');
            }

            urls = urls.where((url) => allFavouriteUrls.contains(url)).toList();

            print(
              'DEBUG: [updateWallpaper] After favourites filter: ${urls.length} URLs',
            );
            print(
              'DEBUG: [updateWallpaper] Total favourite URLs: ${allFavouriteUrls.length}',
            );

            print('DEBUG: [updateWallpaper] Filtered URLs:');
            for (var i = 0; i < urls.length; i++) {
              print('DEBUG: [updateWallpaper] Filtered URL $i: ${urls[i]}');
            }
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
          final cacheDirPath = await getCacheDirectoryPath();
          downloadResult = await _githubService.downloadWallpaper(
            repoUrlToUse,
            effectiveDay,
            resolution,
            '', // Extension is not needed for other tabs
            customCacheDir: cacheDirPath,
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
    print('DEBUG: setWallpaperForUrl called with URL: $url');
    _updateStatus("Downloading wallpaper from URL...");

    try {
      print('DEBUG: Attempting to download file from cache manager...');

      // First check if the wallpaper is already cached
      bool isCached = false;
      File? cachedFile;
      try {
        final cachedFileInfo = await _customCacheManager.getFileFromCache(url);
        if (cachedFileInfo != null && cachedFileInfo.file.existsSync()) {
          isCached = true;
          cachedFile = cachedFileInfo.file;
          print('DEBUG: Wallpaper already cached: ${cachedFile.path}');
        }
      } catch (cacheCheckError) {
        // Ignore cache check errors, we'll try to download
        print('DEBUG: Error checking cache: $cacheCheckError');
      }

      // If not cached, try to download
      if (!isCached) {
        try {
          cachedFile = await _customCacheManager.getSingleFile(url);
          print('DEBUG: File downloaded successfully: ${cachedFile.path}');
        } catch (downloadError) {
          // Check if it's a 404 error
          if (downloadError.toString().contains('404') ||
              downloadError.toString().contains('Invalid statusCode: 404')) {
            print('DEBUG: Wallpaper URL returned 404: $url');
            _updateStatus("Wallpaper URL not found (404)");
            return;
          } else {
            // Re-throw other errors
            throw downloadError;
          }
        }
      }

      if (cachedFile != null) {
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

        print('DEBUG: Setting wallpaper with file path: ${cachedFile.path}');
        _wallpaperService.setWallpaper(cachedFile.path);
        print('DEBUG: Wallpaper set successfully');

        _updateStatus("Wallpaper set from URL: $fileName", file: cachedFile);
        // Save the current weekly wallpaper path for offline preview
        if (_activeTab == 'Weekly') {
          _settingsService.saveCurrentWeeklyWallpaperPath(cachedFile.path);
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
      } else {
        _updateStatus("Failed to get wallpaper file");
      }
    } catch (e) {
      print('DEBUG: Error in setWallpaperForUrl: ${e.toString()}');
      print('DEBUG: Error stack trace: ${e}');
      _updateStatus("Error setting wallpaper: ${e.toString()}");
    }
  }

  /// Sets the next wallpaper in the cycle for Multi, Custom, Saved, and Weekly tabs
  Future<void> setNextWallpaper() async {
    if (_activeTab != 'Multi' &&
        _activeTab != 'Custom' &&
        _activeTab != 'Saved' &&
        _activeTab != 'Weekly') {
      _updateStatus(
        "Next wallpaper only available for Multi, Custom, Saved, and Weekly tabs",
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
        case 'Weekly':
          repoUrlToUse = defaultRepoUrl;
          effectiveDay = getCurrentDay().toLowerCase();
          break;
        case 'Saved':
          // For Saved tab, we cycle through cached images
          await _setNextCachedWallpaper();
          return;
        default:
          return;
      }

      print('DEBUG: Active tab: $_activeTab');
      print('DEBUG: Repo URL to use: $repoUrlToUse');
      print('DEBUG: Resolution: $resolution');
      print('DEBUG: Effective day: $effectiveDay');

      // Use cached URLs if available, otherwise fetch new ones
      List<String> urls;
      if (await _settingsService.getUseOnlyFavourites()) {
        // When using only favourites, fetch from ALL repositories that have favourites
        // IGNORE active tab constraints completely
        print(
          'DEBUG: [FAVOURITES MODE] Fetching URLs from all repositories with favourites (ignoring active tab constraints)...',
        );
        final allUrls = <String>[];

        // Collect all unique repository URLs from favourites
        final repoUrls = <String>{};
        for (final tabFavourites in _favouriteWallpapers.values) {
          for (final favourite in tabFavourites) {
            if (favourite['url'] != null) {
              final uri = Uri.parse(favourite['url']!);
              // Extract repo URL from raw GitHub URL
              final pathSegments = uri.pathSegments;
              if (pathSegments.length >= 3) {
                final user = pathSegments[0];
                final repo = pathSegments[1];
                final repoUrl = 'https://github.com/$user/$repo';
                repoUrls.add(repoUrl);
              }
            }
          }
        }

        print(
          'DEBUG: [FAVOURITES MODE] Found ${repoUrls.length} repositories with favourites:',
        );
        for (var i = 0; i < repoUrls.length; i++) {
          print('DEBUG: [FAVOURITES MODE] Repo $i: ${repoUrls.elementAt(i)}');
        }

        // Fetch URLs from each repository - use 'multi' for all to get wallpapers from Multi folder
        for (final repoUrl in repoUrls) {
          try {
            print(
              'DEBUG: [FAVOURITES MODE] Fetching from: $repoUrl (using multi folder)',
            );
            final repoWallpaperUrls = await _githubService.getImageUrls(
              repoUrl,
              resolution,
              'multi', // Always use 'multi' to get wallpapers from Multi folder
              100,
            );
            allUrls.addAll(repoWallpaperUrls);
            print(
              'DEBUG: [FAVOURITES MODE] Added ${repoWallpaperUrls.length} URLs from $repoUrl',
            );
          } catch (e) {
            print('DEBUG: [FAVOURITES MODE] Error fetching from $repoUrl: $e');
          }
        }

        urls = allUrls;
        print(
          'DEBUG: [FAVOURITES MODE] Total URLs from all repos: ${urls.length}',
        );
      } else {
        // Normal mode - fetch from current repository only
        if (!_cachedUrls.containsKey(_activeTab) ||
            _cachedUrls[_activeTab]!.isEmpty) {
          print('DEBUG: Fetching new URLs from GitHub...');
          urls = await _githubService.getImageUrls(
            repoUrlToUse,
            resolution,
            effectiveDay,
            100,
          );
          print('DEBUG: Fetched ${urls.length} URLs from GitHub');
          _cachedUrls[_activeTab] = urls;
        } else {
          urls = _cachedUrls[_activeTab]!;
          print('DEBUG: Using ${urls.length} cached URLs');
        }
      }

      print('DEBUG: Total URLs before filtering: ${urls.length}');
      for (var i = 0; i < urls.length && i < 5; i++) {
        print('DEBUG: URL $i: ${urls[i]}');
      }

      // If use only favourites is enabled, filter URLs to only include favourited ones from ALL tabs
      if (await _settingsService.getUseOnlyFavourites()) {
        // Collect favourite URLs from all tabs
        final allFavouriteUrls = <String>{};
        for (final tabFavourites in _favouriteWallpapers.values) {
          for (final favourite in tabFavourites) {
            if (favourite['url'] != null) {
              allFavouriteUrls.add(favourite['url']!);
            }
          }
        }

        print('DEBUG: Favourite URLs collected:');
        for (var i = 0; i < allFavouriteUrls.length; i++) {
          print('DEBUG: Favourite $i: ${allFavouriteUrls.elementAt(i)}');
        }

        print('DEBUG: URLs before favourites filter:');
        for (var i = 0; i < urls.length && i < 10; i++) {
          print('DEBUG: URL $i: ${urls[i]}');
        }

        urls = urls.where((url) => allFavouriteUrls.contains(url)).toList();
        print('DEBUG: After favourites filter (all tabs): ${urls.length} URLs');
        print(
          'DEBUG: Total favourite URLs across all tabs: ${allFavouriteUrls.length}',
        );

        print('DEBUG: Filtered URLs:');
        for (var i = 0; i < urls.length; i++) {
          print('DEBUG: Filtered URL $i: ${urls[i]}');
        }
      }

      final sortedUrls = urls..sort();
      final used = _usedWallpapers[_activeTab] ?? [];
      final banned = _bannedWallpapers[_activeTab] ?? [];

      print('DEBUG: Used wallpapers count: ${used.length}');
      print('DEBUG: Banned wallpapers count: ${banned.length}');
      print('DEBUG: Sorted URLs count: ${sortedUrls.length}');

      String? nextUrl;

      // Find the next unused and unbanned wallpaper
      print('DEBUG: Looking for next unused/unbanned wallpaper...');
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
        final isUsed = used.contains(uniqueId);

        print('DEBUG: Checking URL: $url');
        print('DEBUG: FileName: $fileName, UniqueId: $uniqueId');
        print('DEBUG: IsUsed: $isUsed, IsBanned: $isBanned');

        if (!used.contains(uniqueId) && !isBanned) {
          nextUrl = url;
          used.add(uniqueId);
          print('DEBUG: Selected next URL: $nextUrl');
          break;
        } else {
          print('DEBUG: Skipping URL - already used or banned');
        }
      }

      // If no unused wallpaper found, reset the cycle but skip banned ones
      if (nextUrl == null && sortedUrls.isNotEmpty) {
        print('DEBUG: No unused wallpaper found, resetting cycle...');
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
          print('DEBUG: Reset cycle - checking URL: $url, IsBanned: $isBanned');
          if (!isBanned) {
            nextUrl = url;
            used.add(uniqueId);
            print('DEBUG: After reset, selected URL: $nextUrl');
            break;
          }
        }
      }

      _usedWallpapers[_activeTab] = used;
      await _settingsService.saveUsedWallpapers(_usedWallpapers);

      if (nextUrl != null) {
        print('DEBUG: Final selected URL for wallpaper: $nextUrl');
        await setWallpaperForUrl(nextUrl);
      } else {
        print('DEBUG: No wallpapers available after all filtering');
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
    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      final resolution = _currentResolution;
      String repoUrlToUse;
      String effectiveDay = '';

      switch (_activeTab) {
        case 'Weekly':
          repoUrlToUse = defaultRepoUrl;
          // Extract day from file name (e.g., 'monday_1920x1080.jpg' -> 'monday')
          final dayMatch = RegExp(r'^(\w+)_').firstMatch(fileName);
          effectiveDay = dayMatch?.group(1) ?? '';
          break;
        case 'Multi':
          repoUrlToUse = defaultRepoUrl;
          effectiveDay = 'multi';
          break;
        case 'Custom':
          repoUrlToUse = _customRepoUrl;
          break;
        case 'Saved':
          // For cached wallpapers, extract repo URL from the GitHub URL
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 3) {
            final user = pathSegments[0];
            final repo = pathSegments[1];
            repoUrlToUse = 'https://github.com/$user/$repo';
            effectiveDay = 'multi'; // Assume multi for cached wallpapers
          } else {
            _updateStatus("Cannot determine repository for cached wallpaper");
            return;
          }
          break;
        default:
          _updateStatus(
            "Favourite wallpaper not supported for $_activeTab tab",
          );
          return;
      }

      final uniqueId = _generateWallpaperUniqueId(
        repoUrlToUse,
        effectiveDay,
        resolution,
        fileName,
      );

      // Use 'Multi' key for all tabs to share favourite wallpapers
      final tabKey = 'Multi';

      // Check if already favourited
      if (!_favouriteWallpapersService.isWallpaperFavourited(
        _favouriteWallpapers,
        tabKey,
        uniqueId,
      )) {
        // First check if the wallpaper is already cached
        bool isCached = false;
        try {
          final cachedFileInfo = await _customCacheManager.getFileFromCache(
            url,
          );
          if (cachedFileInfo != null && cachedFileInfo.file.existsSync()) {
            isCached = true;
            _updateStatus("Wallpaper already cached, adding to favourites");
          }
        } catch (cacheCheckError) {
          // Ignore cache check errors, we'll try to download
          print(
            'Error checking cache for favourited wallpaper: $cacheCheckError',
          );
        }

        // If not cached, try to cache the wallpaper
        if (!isCached) {
          try {
            await _customCacheManager.getSingleFile(url);
            _updateStatus("Wallpaper cached and added to favourites");
          } catch (cacheError) {
            // Check if it's a 404 error
            if (cacheError.toString().contains('404') ||
                cacheError.toString().contains('Invalid statusCode: 404')) {
              _updateStatus(
                "Wallpaper URL not found (404), but added to favourites for later",
              );
              print(
                'Wallpaper URL returned 404, but proceeding with favouriting: $url',
              );
            } else {
              _updateStatus(
                "Warning: Failed to cache wallpaper, but added to favourites",
              );
              print('Error caching favourited wallpaper: $cacheError');
            }
          }
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
    try {
      // Use 'Multi' key for all tabs to share favourite wallpapers
      final tabKey = 'Multi';

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
      final cacheDirPath = await getCacheDirectoryPath();
      final cacheDir = Directory(cacheDirPath);

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
      final cacheDirPath = await getCacheDirectoryPath();
      final cacheDir = Directory(cacheDirPath);

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

      // If use only favourites is enabled, filter cached images to only include favourited ones
      List<File> filteredImageFiles = imageFiles;
      if (await _settingsService.getUseOnlyFavourites()) {
        print(
          'DEBUG: [SAVED TAB FAVOURITES MODE] Filtering cached images to favourites only',
        );

        // Collect all favourite URLs from all tabs
        final allFavouriteUrls = <String>{};
        for (final tabFavourites in _favouriteWallpapers.values) {
          for (final favourite in tabFavourites) {
            if (favourite['url'] != null) {
              allFavouriteUrls.add(favourite['url']!);
            }
          }
        }

        print(
          'DEBUG: [SAVED TAB FAVOURITES MODE] Total favourite URLs: ${allFavouriteUrls.length}',
        );

        if (allFavouriteUrls.isEmpty) {
          print('DEBUG: [SAVED TAB FAVOURITES MODE] No favourite URLs found');
          _updateStatus("No favourited wallpapers found");
          return;
        }

        // First, ensure all favourite wallpapers are cached
        print(
          'DEBUG: [SAVED TAB FAVOURITES MODE] Ensuring all favourites are cached...',
        );
        for (final favouriteUrl in allFavouriteUrls) {
          try {
            // Check if already cached
            final existingFileInfo = await _customCacheManager.getFileFromCache(
              favouriteUrl,
            );
            if (existingFileInfo == null ||
                !existingFileInfo.file.existsSync()) {
              print(
                'DEBUG: [SAVED TAB FAVOURITES MODE] Downloading and caching: $favouriteUrl',
              );
              // Download and cache the wallpaper
              await _customCacheManager.getSingleFile(favouriteUrl);
              print(
                'DEBUG: [SAVED TAB FAVOURITES MODE] Successfully cached: $favouriteUrl',
              );
            } else {
              print(
                'DEBUG: [SAVED TAB FAVOURITES MODE] Already cached: $favouriteUrl',
              );
            }
          } catch (e) {
            print(
              'DEBUG: [SAVED TAB FAVOURITES MODE] Error caching $favouriteUrl: $e',
            );
          }
        }

        // Now get all cached favourite files
        final favouriteCachedFiles = <File>[];
        for (final favouriteUrl in allFavouriteUrls) {
          try {
            print(
              'DEBUG: [SAVED TAB FAVOURITES MODE] Getting cached file for URL: $favouriteUrl',
            );
            // Get the cached file info for this URL
            final fileInfo = await _customCacheManager.getFileFromCache(
              favouriteUrl,
            );

            if (fileInfo != null && fileInfo.file.existsSync()) {
              print(
                'DEBUG: [SAVED TAB FAVOURITES MODE] Found cached file: ${fileInfo.file.path}',
              );
              favouriteCachedFiles.add(fileInfo.file);
            } else {
              print(
                'DEBUG: [SAVED TAB FAVOURITES MODE] Still no cached file found for URL: $favouriteUrl',
              );
            }
          } catch (e) {
            print(
              'DEBUG: [SAVED TAB FAVOURITES MODE] Error getting cached file for $favouriteUrl: $e',
            );
          }
        }

        print(
          'DEBUG: [SAVED TAB FAVOURITES MODE] Found ${favouriteCachedFiles.length} cached favourite files',
        );

        if (favouriteCachedFiles.isEmpty) {
          print(
            'DEBUG: [SAVED TAB FAVOURITES MODE] No favourite wallpapers could be cached',
          );
          _updateStatus("No favourited wallpapers available");
          return;
        }

        filteredImageFiles = favouriteCachedFiles;
        print(
          'DEBUG: [SAVED TAB FAVOURITES MODE] Using ${filteredImageFiles.length} favourited cached files',
        );
      }

      // Sort files by name for consistent cycling
      filteredImageFiles.sort((a, b) => a.path.compareTo(b.path));

      // Get used wallpapers for Saved tab
      final used = _usedWallpapers['Saved'] ?? [];
      File? nextFile;

      // Find the next unused cached wallpaper
      for (final file in filteredImageFiles) {
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
      if (nextFile == null && filteredImageFiles.isNotEmpty) {
        used.clear();
        nextFile = filteredImageFiles.first;
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

  /// Gets cached wallpaper URLs for a specific repository and day
  Future<List<String>> getCachedWallpaperUrls(
    String repoUrl,
    String day,
    String resolution,
  ) async {
    final cachedUrls = <String>[];

    try {
      // Get all cached files from the cache manager
      final cacheDirPath = await getCacheDirectoryPath();
      final cacheDir = Directory(cacheDirPath);

      if (!await cacheDir.exists()) {
        return cachedUrls;
      }

      // List all files in cache directory
      final files =
          cacheDir.listSync().where((file) => file is File).cast<File>();

      for (final file in files) {
        final fileName = file.path.split(Platform.pathSeparator).last;

        // Check if this file corresponds to the requested repo/day/resolution
        // We need to reconstruct the URL pattern that would match this file
        for (final ext in supportedImageExtensions) {
          // Try different possible filename patterns
          final possibleFileNames = [
            '${day}_$resolution$ext', // Weekly format: monday_1920x1080.jpg
            '${resolution}_$fileName', // Multi/Custom format variations
            fileName, // Direct filename match
          ];

          for (final possibleName in possibleFileNames) {
            // Construct the expected GitHub URL
            final expectedUrl = '$repoUrl/raw/main/$day/$possibleName';

            try {
              // Check if this URL is cached and matches our file
              final cachedFileInfo = await _customCacheManager.getFileFromCache(
                expectedUrl,
              );
              if (cachedFileInfo != null &&
                  cachedFileInfo.file.existsSync() &&
                  cachedFileInfo.file.path == file.path) {
                cachedUrls.add(expectedUrl);
                break;
              }
            } catch (e) {
              // Continue checking other patterns
            }
          }

          if (cachedUrls.isNotEmpty && cachedUrls.last.contains(fileName)) {
            break; // Found a match for this file
          }
        }
      }
    } catch (e) {
      print('Error getting cached wallpaper URLs: $e');
    }

    return cachedUrls;
  }

  /// Automatically selects the best resolution for the screen if not manually set
  Future<void> _autoSelectResolutionIfNeeded() async {
    try {
      // Check if resolution has been manually set by user
      final isAutoSelected = await _settingsService.isResolutionAutoSelected();

      // If resolution was manually set by user, don't auto-select
      if (!isAutoSelected) {
        // Check if current resolution is still the default
        final currentResolution = await _settingsService.getResolution();
        if (currentResolution == '1920x1080') {
          // Still default, auto-select based on screen size
          final bestResolution = selectBestResolutionForScreen();
          if (bestResolution != currentResolution) {
            print(
              'Auto-selecting resolution: $bestResolution (screen size: ${getPrimaryDisplayResolution()})',
            );
            _currentResolution = bestResolution;
            await _settingsService.saveResolution(bestResolution);
            await _settingsService.setResolutionAutoSelected(true);
          }
        }
      }
    } catch (e) {
      print('Error in auto-select resolution: $e');
      // Don't fail initialization if auto-selection fails
    }
  }
}
