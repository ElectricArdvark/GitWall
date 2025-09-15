import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' show Colors;
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../state/app_state.dart';

/// Service class to manage banned wallpapers functionality
class BannedWallpapersService {
  static const String _bannedWallpapersFileName = 'banned_wallpapers.json';

  BannedWallpapersService();

  /// Gets the file path for storing banned wallpapers
  Future<String> _getBannedWallpapersPath() async {
    final directory = await getApplicationSupportDirectory();
    final appDataDir = directory.parent;
    final cachePath = p.join(appDataDir.path, '..', 'GitWall');
    await Directory(cachePath).create(recursive: true);
    return p.join(cachePath, _bannedWallpapersFileName);
  }

  /// Saves banned wallpapers to persistent storage
  Future<void> saveBannedWallpapers(
    Map<String, List<Map<String, String>>> bannedWallpapers,
  ) async {
    try {
      final filePath = await _getBannedWallpapersPath();
      final file = File(filePath);
      final serialized = jsonEncode(bannedWallpapers);
      await file.writeAsString(serialized);
    } catch (e) {
      // Silently handle errors to avoid disrupting the app
      print('Error saving banned wallpapers: $e');
    }
  }

  /// Loads banned wallpapers from persistent storage
  Future<Map<String, List<Map<String, String>>>> getBannedWallpapers() async {
    try {
      final filePath = await _getBannedWallpapersPath();
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
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((item) => Map<String, String>.from(item))
              .toList(),
        ),
      );
      return result;
    } catch (e) {
      print('Error loading banned wallpapers: $e');
      return {};
    }
  }

  /// Checks if a wallpaper is banned for a specific tab
  bool isWallpaperBanned(
    Map<String, List<Map<String, String>>> bannedWallpapers,
    String tabKey,
    String uniqueId,
  ) {
    final banned = bannedWallpapers[tabKey] ?? [];
    return banned.any((entry) => entry['uniqueId'] == uniqueId);
  }

  /// Bans a wallpaper for a specific tab
  Future<Map<String, List<Map<String, String>>>> banWallpaper(
    Map<String, List<Map<String, String>>> bannedWallpapers,
    String tabKey,
    String uniqueId,
    String url,
  ) async {
    final banned = bannedWallpapers[tabKey] ?? [];
    final wallpaperEntry = {'uniqueId': uniqueId, 'url': url};

    // Check if already banned
    if (!banned.any((entry) => entry['uniqueId'] == uniqueId)) {
      banned.add(wallpaperEntry);
      bannedWallpapers[tabKey] = banned;
      await saveBannedWallpapers(bannedWallpapers);
    }

    return bannedWallpapers;
  }

  /// Unbans a wallpaper for a specific tab
  Future<Map<String, List<Map<String, String>>>> unbanWallpaper(
    Map<String, List<Map<String, String>>> bannedWallpapers,
    String tabKey,
    String uniqueId,
  ) async {
    final banned = bannedWallpapers[tabKey] ?? [];
    final index = banned.indexWhere((entry) => entry['uniqueId'] == uniqueId);

    if (index != -1) {
      banned.removeAt(index);
      bannedWallpapers[tabKey] = banned;
      await saveBannedWallpapers(bannedWallpapers);
    }

    return bannedWallpapers;
  }

  /// Filters out banned wallpapers from a list of wallpaper URLs
  List<String> filterBannedWallpapers(
    List<String> urls,
    Map<String, List<Map<String, String>>> bannedWallpapers,
    String tabKey,
    String Function(String url) uniqueIdGenerator,
  ) {
    final banned = bannedWallpapers[tabKey] ?? [];

    return urls.where((url) {
      final uniqueId = uniqueIdGenerator(url);
      return !banned.any((entry) => entry['uniqueId'] == uniqueId);
    }).toList();
  }

  /// Gets banned wallpapers for a specific tab
  List<Map<String, String>> getBannedWallpapersForTab(
    Map<String, List<Map<String, String>>> bannedWallpapers,
    String tabKey,
  ) {
    return bannedWallpapers[tabKey] ?? [];
  }

  /// Builds the banned preview widget
  Widget buildBannedPreview(
    Map<String, List<Map<String, String>>> bannedWallpapers,
    String tabKey,
    AppState appState,
    StateSetter setState,
  ) {
    final banned = bannedWallpapers[tabKey] ?? [];
    if (banned.isEmpty) {
      return Center(
        child: Text(
          'No banned wallpapers yet.',
          style: TextStyle(
            color: appState.isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    // Check if internet is available
    return FutureBuilder<bool>(
      future: appState.isInternetAvailable(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true; // Default to true while loading

        if (!isOnline) {
          // Offline: show message that banned wallpapers are not cached
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Banned wallpapers are not cached.',
                  style: TextStyle(
                    color: appState.isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Tooltip(
                  message: 'Check connection and retry',
                  child: Button(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        }

        // Online: show the grid of banned wallpapers
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
          ),
          itemCount: banned.length,
          itemBuilder: (context, index) {
            final bannedWallpaper = banned[index];
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: GestureDetector(
                onTap:
                    () => appState.setWallpaperForUrl(bannedWallpaper['url']!),
                onSecondaryTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => ContentDialog(
                          title: const Text('Unban Wallpaper?'),
                          content: const Text(
                            'Would you like to unban this wallpaper?',
                          ),
                          actions: [
                            Button(
                              onPressed: () {
                                appState.unbanWallpaper(
                                  bannedWallpaper['uniqueId']!,
                                );
                                Navigator.of(context).pop();
                                setState(() {}); // Rebuild to reflect changes
                              },
                              child: const Text('Unban'),
                            ),
                            Button(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                  );
                },
                child: Image.network(
                  bannedWallpaper['url']!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(
                          color:
                              appState.isDarkTheme
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        FluentIcons.error,
                        color:
                            appState.isDarkTheme ? Colors.white : Colors.black,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
