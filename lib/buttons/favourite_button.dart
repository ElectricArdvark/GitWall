import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' show Colors;
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:gitwall/services/settings_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../state/app_state.dart';

/// Service class to manage favourite wallpapers functionality
class FavouriteWallpapersService {
  static const String _favouriteWallpapersFileName =
      'favourite_wallpapers.json';
  final SettingsService _settingsService = SettingsService();

  FavouriteWallpapersService();

  /// Gets the file path for storing favourite wallpapers
  Future<String> _getFavouriteWallpapersPath() async {
    final directory = await getApplicationSupportDirectory();
    final appDataDir = directory.parent;
    final cachePath = p.join(appDataDir.path, '..', 'GitWall');
    await Directory(cachePath).create(recursive: true);
    return p.join(cachePath, _favouriteWallpapersFileName);
  }

  /// Saves favourite wallpapers to persistent storage
  Future<void> saveFavouriteWallpapers(
    Map<String, List<Map<String, String>>> favouriteWallpapers,
  ) async {
    try {
      final filePath = await _getFavouriteWallpapersPath();
      final file = File(filePath);
      final serialized = jsonEncode(favouriteWallpapers);
      await file.writeAsString(serialized);
    } catch (e) {
      // Silently handle errors to avoid disrupting the app
      print('Error saving favourite wallpapers: $e');
    }
  }

  /// Loads favourite wallpapers from persistent storage
  Future<Map<String, List<Map<String, String>>>>
  getFavouriteWallpapers() async {
    try {
      final filePath = await _getFavouriteWallpapersPath();
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
      print('Error loading favourite wallpapers: $e');
      return {};
    }
  }

  /// Checks if a wallpaper is favourited for a specific tab
  bool isWallpaperFavourited(
    Map<String, List<Map<String, String>>> favouriteWallpapers,
    String tabKey,
    String uniqueId,
  ) {
    final favourites = favouriteWallpapers[tabKey] ?? [];
    return favourites.any((entry) => entry['uniqueId'] == uniqueId);
  }

  /// Favourites a wallpaper for a specific tab
  Future<Map<String, List<Map<String, String>>>> favouriteWallpaper(
    Map<String, List<Map<String, String>>> favouriteWallpapers,
    String tabKey,
    String uniqueId,
    String url,
  ) async {
    final favourites = favouriteWallpapers[tabKey] ?? [];
    final wallpaperEntry = {'uniqueId': uniqueId, 'url': url};

    // Check if already favourited
    if (!favourites.any((entry) => entry['uniqueId'] == uniqueId)) {
      favourites.add(wallpaperEntry);
      favouriteWallpapers[tabKey] = favourites;
      await saveFavouriteWallpapers(favouriteWallpapers);
    }

    return favouriteWallpapers;
  }

  /// Unfavourites a wallpaper for a specific tab
  Future<Map<String, List<Map<String, String>>>> unfavouriteWallpaper(
    Map<String, List<Map<String, String>>> favouriteWallpapers,
    String tabKey,
    String uniqueId,
  ) async {
    final favourites = favouriteWallpapers[tabKey] ?? [];
    final index = favourites.indexWhere(
      (entry) => entry['uniqueId'] == uniqueId,
    );

    if (index != -1) {
      favourites.removeAt(index);
      favouriteWallpapers[tabKey] = favourites;
      await saveFavouriteWallpapers(favouriteWallpapers);
    }

    return favouriteWallpapers;
  }

  /// Gets favourite wallpapers for a specific tab
  List<Map<String, String>> getFavouriteWallpapersForTab(
    Map<String, List<Map<String, String>>> favouriteWallpapers,
    String tabKey,
  ) {
    return favouriteWallpapers[tabKey] ?? [];
  }

  /// Builds the favourites preview widget
  Widget buildFavouritesPreview(
    Map<String, List<Map<String, String>>> favouriteWallpapers,
    String tabKey,
    AppState appState,
    StateSetter setState,
  ) {
    final favourites = favouriteWallpapers[tabKey] ?? [];
    if (favourites.isEmpty) {
      return Column(
        children: [
          // Toggle button at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<bool>(
                  future: _settingsService.getUseOnlyFavourites(),
                  builder: (context, snapshot) {
                    final useOnlyFavouritesEnabled = snapshot.data ?? false;
                    return Tooltip(
                      message:
                          useOnlyFavouritesEnabled
                              ? 'Disable using only favourite wallpapers'
                              : 'Enable using only favourite wallpapers',
                      child: ToggleButton(
                        checked: useOnlyFavouritesEnabled,
                        onChanged: (value) async {
                          await _settingsService.setUseOnlyFavourites(value);
                          setState(() {});
                        },
                        child: Text(
                          'Set favourite as wallpaper',
                          style: TextStyle(
                            color:
                                appState.isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'No favourite wallpapers yet.',
                style: TextStyle(
                  color: appState.isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        // Toggle button at the top
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<bool>(
                future: _settingsService.getUseOnlyFavourites(),
                builder: (context, snapshot) {
                  final useOnlyFavouritesEnabled = snapshot.data ?? false;
                  return Tooltip(
                    message:
                        useOnlyFavouritesEnabled
                            ? 'Disable using only favourite wallpapers'
                            : 'Enable using only favourite wallpapers',
                    child: ToggleButton(
                      checked: useOnlyFavouritesEnabled,
                      onChanged: (value) async {
                        await _settingsService.setUseOnlyFavourites(value);
                        setState(() {});
                      },
                      child: Text(
                        'Set favourite as wallpaper',
                        style: TextStyle(
                          color:
                              appState.isDarkTheme
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: favourites.length,
            itemBuilder: (context, index) {
              final favourite = favourites[index];
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: GestureDetector(
                  onTap: () => appState.setWallpaperForUrl(favourite['url']!),
                  onSecondaryTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => ContentDialog(
                            title: const Text('Unfavourite Wallpaper?'),
                            content: const Text(
                              'Would you like to remove this wallpaper from your favourites?',
                            ),
                            actions: [
                              Button(
                                onPressed: () {
                                  appState.unfavouriteWallpaper(
                                    favourite['uniqueId']!,
                                  );
                                  Navigator.of(context).pop();
                                  setState(() {}); // Rebuild to reflect changes
                                },
                                child: const Text('Unfavourite'),
                              ),
                              Button(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: FutureBuilder<File?>(
                    future: _getCachedFileForFavourite(
                      favourite['url']!,
                      appState,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                      }

                      final cachedFile = snapshot.data;
                      if (cachedFile != null && cachedFile.existsSync()) {
                        // Use cached file if available
                        return Image.file(
                          cachedFile,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to network if cached file fails
                            return Image.network(
                              favourite['url']!,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
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
                                        appState.isDarkTheme
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      } else {
                        // Use network image if not cached
                        return Image.network(
                          favourite['url']!,
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
                                    appState.isDarkTheme
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Gets the cached file for a favourite URL if it exists
  Future<File?> _getCachedFileForFavourite(
    String url,
    AppState appState,
  ) async {
    try {
      final fileInfo = await appState.customCacheManager.getFileFromCache(url);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        return fileInfo.file;
      }
    } catch (e) {
      print('Error getting cached file for favourite: $e');
    }
    return null;
  }
}

/// A button widget for favouriting wallpapers
class FavouriteButton extends StatelessWidget {
  final String url;
  final Function(String) onFavourite;
  final bool canFavourite;

  const FavouriteButton({
    super.key,
    required this.url,
    required this.onFavourite,
    this.canFavourite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!canFavourite) return const SizedBox.shrink();

        return Tooltip(
          message: 'Add to favourites',
          child: Button(
            onPressed: () {
              onFavourite(url);
              Navigator.of(context).pop();
            },
            child: const Text('Favourite'),
          ),
        );
      },
    );
  }
}
