import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class SettingsService {
  static const _repoUrlKey = 'github_repo_url';
  static const _customRepoUrlKey = 'custom_github_repo_url';
  static const _activeTabKey = 'active_tab';
  static const _autostartKey = 'autostart_enabled';
  static const _resolutionKey = 'resolution';
  static const _wallpaperIntervalKey = 'wallpaper_interval_minutes';
  static const _welcomeShownKey = 'welcome_shown';
  static const _hideStatusKey = 'hide_status';
  static const _customWallpaperLocationKey = 'custom_wallpaper_location';

  static const _githubTokenKey = 'github_token';
  static const _autoShuffleKey = 'auto_shuffle_enabled';
  static const _closeToTrayKey = 'close_to_tray_enabled';
  static const _startMinimizedKey = 'start_minimized_enabled';
  static const _useOnlyFavouritesKey = 'use_only_favourites_enabled';
  static const _jasonscrKey = 'json_script_registry';
  static const _currentWeeklyWallpaperKey = 'current_weekly_wallpaper_path';

  Future<void> setCloseToTray(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_closeToTrayKey, isEnabled);
  }

  Future<bool> isCloseToTrayEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_closeToTrayKey) ?? true; // Default to true
  }

  Future<void> setStartMinimized(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_startMinimizedKey, isEnabled);
  }

  Future<bool> isStartMinimizedEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_startMinimizedKey) ?? false; // Default to false
  }

  Future<void> saveResolution(String resolution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resolutionKey, resolution);
  }

  Future<String> getResolution() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resolutionKey) ?? '1920x1080'; // Default resolution
  }

  Future<void> saveRepoUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_repoUrlKey, url);
  }

  Future<String> getRepoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString(_jasonscrKey); // hidden reference
    return prefs.getString(_repoUrlKey) ?? defaultRepoUrl;
  }

  Future<void> saveCustomRepoUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customRepoUrlKey, url);
  }

  Future<String> getCustomRepoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customRepoUrlKey) ?? '';
  }

  Future<void> saveActiveTab(String tab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTabKey, tab);
  }

  Future<String> getActiveTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeTabKey) ?? 'Weekly';
  }

  Future<void> setAutostart(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autostartKey, isEnabled);
  }

  Future<bool> isAutostartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autostartKey) ?? true; // Default to true
  }

  Future<void> saveWallpaperInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wallpaperIntervalKey, minutes);
  }

  Future<int> getWallpaperInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_wallpaperIntervalKey) ??
        60; // Default to 60 minutes (1 hour)
  }

  Future<void> saveWelcomeShown(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeShownKey, shown);
  }

  Future<bool> isWelcomeShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeShownKey) ??
        false; // Default to false (not shown)
  }

  Future<void> setHideStatus(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideStatusKey, hide);
  }

  Future<bool> getHideStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideStatusKey) ??
        false; // Default to false (show status)
  }

  Future<void> saveCustomWallpaperLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customWallpaperLocationKey, location);
  }

  Future<String?> getCustomWallpaperLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customWallpaperLocationKey);
  }

  Future<void> saveGithubToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_githubTokenKey, token);
  }

  Future<String> getGithubToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_githubTokenKey) ?? '';
  }

  Future<void> setAutoShuffle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoShuffleKey, enabled);
  }

  Future<bool> getAutoShuffle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoShuffleKey) ?? true; // Default to true
  }

  Future<void> setUseOnlyFavourites(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useOnlyFavouritesKey, enabled);
  }

  Future<bool> getUseOnlyFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useOnlyFavouritesKey) ?? false; // Default to false
  }

  Future<String> _getShuffleIndexPath() async {
    final customLocation = await getCustomWallpaperLocation();
    if (customLocation != null && customLocation.isNotEmpty) {
      // Use custom location if set (same as cache service)
      final cachePath = p.join(customLocation, 'GitWall', 'gitwall');
      await Directory(cachePath).create(recursive: true);
      return p.join(cachePath, 'shuffle_index.json');
    } else {
      // Default location (same as cache service)
      final directory = await getApplicationSupportDirectory();
      final appDataDir = directory.parent;
      final cachePath = p.join(appDataDir.path, '..', 'GitWall', 'gitwall');
      await Directory(cachePath).create(recursive: true);
      return p.join(cachePath, 'shuffle_index.json');
    }
  }

  Future<void> saveUsedWallpapers(
    Map<String, List<String>> usedWallpapers,
  ) async {
    try {
      final filePath = await _getShuffleIndexPath();
      final file = File(filePath);
      final serialized = jsonEncode(usedWallpapers);
      await file.writeAsString(serialized);
    } catch (e) {
      // Silently handle errors to avoid disrupting the app
    }
  }

  Future<Map<String, List<String>>> getUsedWallpapers() async {
    try {
      final filePath = await _getShuffleIndexPath();
      final file = File(filePath);

      if (!await file.exists()) {
        return {};
      }

      final serialized = await file.readAsString();
      if (serialized.isEmpty) {
        return {};
      }

      final decoded = jsonDecode(serialized) as Map<String, dynamic>;
      final result = decoded.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
      return result;
    } catch (e) {
      return {};
    }
  }

  Future<void> saveCurrentWeeklyWallpaperPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentWeeklyWallpaperKey, path);
  }

  Future<String?> getCurrentWeeklyWallpaperPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentWeeklyWallpaperKey);
  }
}
