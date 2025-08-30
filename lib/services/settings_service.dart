import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class SettingsService {
  static const _repoUrlKey = 'github_repo_url';
  static const _autostartKey = 'autostart_enabled';
  static const _resolutionKey = 'resolution';

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

  Future<void> setAutostart(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autostartKey, isEnabled);
  }

  Future<bool> isAutostartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autostartKey) ?? true; // Default to true
  }
}
