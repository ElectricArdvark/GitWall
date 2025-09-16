import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/widgets/common_widget.dart';
import 'package:gitwall/buttons/next_wallpaper_button.dart';
import 'package:gitwall/buttons/shuffle_button.dart';
import 'package:gitwall/widgets/wallpaper_options_widget.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../state/app_state.dart';

class WeeklyPage extends StatefulWidget {
  final AppState appState;
  const WeeklyPage({super.key, required this.appState});

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage> {
  bool _showFavouritesPreview = false;
  bool _showBannedPreview = false;

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      description: 'Uses the default repository for weekly wallpapers.',
      previewTitle: 'Wallpaper Preview:',
      extraButtons:
          _showFavouritesPreview
              ? Consumer<AppState>(
                builder: (context, appState, child) {
                  return Row(
                    children: [
                      NextWallpaperButton(appState: appState),
                      const SizedBox(width: 8),
                      ShuffleButton(appState: appState),
                      const SizedBox(width: 8),
                    ],
                  );
                },
              )
              : null,
      previewContent:
          _showBannedPreview
              ? widget.appState.bannedWallpapersService.buildBannedPreview(
                widget.appState.bannedWallpapers,
                'Multi',
                widget.appState,
                setState,
              )
              : _showFavouritesPreview
              ? widget.appState.favouriteWallpapersService
                  .buildFavouritesPreview(
                    widget.appState.favouriteWallpapers,
                    'Multi',
                    widget.appState,
                    setState,
                  )
              : _buildCurrentWallpaperPreview(),
      onToggleChanged: (favourites, banned) {
        setState(() {
          _showFavouritesPreview = favourites;
          _showBannedPreview = banned;
        });
      },
    );
  }

  Widget _buildCurrentWallpaperPreview() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getWallpaperPreviewData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Consumer<AppState>(
            builder: (context, appState, child) {
              return Center(
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    color: appState.isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              );
            },
          );
        }

        final data = snapshot.data;
        if (data == null || data['file'] == null) {
          // No internet and no cached wallpaper available
          return Consumer<AppState>(
            builder: (context, appState, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No Internet Available',
                      style: TextStyle(
                        color:
                            appState.isDarkTheme ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Tooltip(
                      message: 'Switch to saved wallpapers',
                      child: Button(
                        onPressed: () {
                          // Navigate to cached page (Saved tab)
                          widget.appState.setActiveTab('Saved');
                        },
                        child: const Text('Use Saved Wallpapers Instead'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Tooltip(
                      message: 'Retry loading wallpaper',
                      child: Button(
                        onPressed:
                            () =>
                                widget.appState.updateWallpaper(isManual: true),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        final file = data['file'] as File;
        final wallpaperUrl = data['url'] as String?;

        return GestureDetector(
          onSecondaryTap: () {
            final day = _getCurrentDay();
            final capitalizedDay =
                day[0].toUpperCase() + day.substring(1).toLowerCase();
            final resolution = widget.appState.currentResolution;
            final extension = file.path.split('.').last;

            final fallbackUrl =
                'https://raw.githubusercontent.com/ElectricArdvark/GitWall-WP/main/Weekly/$capitalizedDay/${capitalizedDay}_$resolution.$extension';

            final urlToFavourite = wallpaperUrl ?? fallbackUrl;
            WallpaperOptionsDialog.show(
              context,
              url: urlToFavourite,
              canBan: false,
              onFavourite: widget.appState.favouriteWallpaper,
            );
          },
          child: Image.file(file, fit: BoxFit.fill, key: ValueKey(file.path)),
        );
      },
    );
  }

  Future<String?> _getWallpaperUrl(File file) async {
    try {
      // Try to get the URL from cache metadata
      final cacheDirPath = await widget.appState.getCacheDirectoryPath();
      final cacheDir = Directory(cacheDirPath);

      if (!await cacheDir.exists()) {
        return null;
      }

      // Load cache metadata from gitwall_cache.json
      final appDataDir = await getApplicationSupportDirectory();
      final cacheJsonFile = File('${appDataDir.path}\\gitwall_cache.json');

      if (!await cacheJsonFile.exists()) {
        return null;
      }

      final cacheJson = await cacheJsonFile.readAsString();
      final List<dynamic> cacheData = jsonDecode(cacheJson);

      // Convert to map by relativePath for easy lookup
      final cacheMetadata = Map.fromIterable(
        cacheData,
        key: (item) => item['relativePath'] as String,
        value: (item) => item,
      );

      final fileName = file.path.split('\\').last;
      final cacheEntry = cacheMetadata[fileName];

      if (cacheEntry != null) {
        return cacheEntry['url'] as String;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getWallpaperPreviewData() async {
    // If a wallpaper is already set, display it
    if (widget.appState.currentWallpaperFile != null &&
        widget.appState.currentWallpaperFile!.existsSync()) {
      final url = await _getWallpaperUrl(widget.appState.currentWallpaperFile!);
      return {'file': widget.appState.currentWallpaperFile, 'url': url};
    }

    // If no wallpaper is set, check for internet
    final isInternetAvailable = await widget.appState.isInternetAvailable();
    if (!isInternetAvailable) {
      // No internet - try to find cached weekly wallpaper for current day
      final day = _getCurrentDay();

      try {
        // Load cache metadata to find cached weekly wallpapers
        final appDataDir = await getApplicationSupportDirectory();
        final cacheJsonFile = File('${appDataDir.path}\\gitwall_cache.json');

        if (!await cacheJsonFile.exists()) {
          return {};
        }

        final cacheJson = await cacheJsonFile.readAsString();
        final List<dynamic> cacheData = jsonDecode(cacheJson);

        // Look for weekly wallpapers that match the current day
        for (final entry in cacheData) {
          final url = entry['url'] as String?;
          final relativePath = entry['relativePath'] as String?;

          if (url != null && relativePath != null) {
            // Check if this is a weekly wallpaper for the current day
            if (url.contains('/Weekly/') &&
                url.toLowerCase().contains('/${day}/')) {
              // Try to get the cached file using the cache manager
              final cachedFileInfo = await widget.appState.customCacheManager
                  .getFileFromCache(url);

              if (cachedFileInfo != null && cachedFileInfo.file.existsSync()) {
                return {'file': cachedFileInfo.file, 'url': url};
              }
            }
          }
        }

        // No cached wallpaper found for current day
        return {};
      } catch (e) {
        return {};
      }
    }
    // No current wallpaper, but internet is available
    return {};
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[now.weekday - 1];
  }
}
