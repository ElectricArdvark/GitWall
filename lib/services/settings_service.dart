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
}
