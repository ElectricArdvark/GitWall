import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/widgets/common_widget.dart';
import 'package:gitwall/buttons/next_wallpaper_button.dart';
import 'package:gitwall/buttons/shuffle_button.dart';
import 'package:gitwall/widgets/wallpaper_options_widget.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';

class CachedPage extends StatefulWidget {
  final AppState appState;
  const CachedPage({super.key, required this.appState});

  @override
  State<CachedPage> createState() => _CachedPageState();
}

class _CachedPageState extends State<CachedPage> {
  List<Map<String, dynamic>> _cachedImages = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showFavouritesPreview = false;
  bool _showBannedPreview = false;

  @override
  void initState() {
    super.initState();
    _loadCachedImages();
  }

  @override
  void didUpdateWidget(CachedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Also check for changes when widget updates
    if (widget.appState.bannedWallpapersChanged) {
      widget.appState.resetBannedWallpapersChanged();
      _loadCachedImages();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadCachedImages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Get the cache directory based on custom location setting
      final cacheDirPath = await widget.appState.getCacheDirectoryPath();
      final cacheDir = Directory(cacheDirPath);

      // Create directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Load cache metadata from gitwall_cache.json (stored in app data directory)
      final appDataDir = await getApplicationSupportDirectory();
      final cacheJsonFile = File('${appDataDir.path}\\gitwall_cache.json');
      Map<String, dynamic> cacheMetadata = {};
      if (await cacheJsonFile.exists()) {
        final cacheJson = await cacheJsonFile.readAsString();
        final List<dynamic> cacheData = jsonDecode(cacheJson);
        // Convert to map by relativePath for easy lookup
        cacheMetadata = Map.fromIterable(
          cacheData,
          key: (item) => item['relativePath'] as String,
          value: (item) => item,
        );
      } else {}

      final files =
          cacheDir.listSync().where((file) => file is File).cast<File>();
      // Filter to only image files
      final imageFiles =
          files.where((file) {
            final extension = file.path.split('.').last.toLowerCase();
            return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
          }).toList();

      // Get banned URLs from ALL tabs for direct comparison
      final allBannedWallpapers = <Map<String, String>>[];
      widget.appState.bannedWallpapers.forEach((tabKey, wallpapers) {
        allBannedWallpapers.addAll(wallpapers);
      });
      final bannedUrls =
          allBannedWallpapers.map((banned) => banned['url'] as String).toSet();

      // Filter out banned wallpapers by URL comparison
      final filteredImages = <Map<String, dynamic>>[];
      for (final file in imageFiles) {
        final fileName = p.basename(file.path);
        final cacheEntry = cacheMetadata[fileName];

        if (cacheEntry != null) {
          final originalUrl = cacheEntry['url'] as String;

          // Check if URL is in banned URLs set
          final isBanned = bannedUrls.contains(originalUrl);

          if (!isBanned) {
            filteredImages.add({'file': file, 'url': originalUrl});
          } else {}
        } else {
          // Include files without metadata (fallback for compatibility)
          filteredImages.add({'file': file, 'url': null});
        }
      }

      setState(() {
        _cachedImages = filteredImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openCacheDirectory() async {
    final cacheDirPath = await widget.appState.getCacheDirectoryPath();
    final uri = Uri.directory(cacheDirPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error
      print('Could not launch $cacheDirPath');
    }
  }

  void _deleteCachedImage(Map<String, dynamic> item) async {
    try {
      await item['file'].delete();
      setState(() {
        _cachedImages.remove(item);
      });
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Widget _buildPreviewContent() {
    if (_cachedImages.isEmpty && _isLoading) {
      return const LoadingWidget();
    }
    if (_hasError) {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error loading cached images: $_errorMessage',
                  style: TextStyle(
                    color: appState.isDarkTheme ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message: 'Retry loading cached images',
                  child: Button(
                    onPressed: () => _loadCachedImages(),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    if (_cachedImages.isEmpty) {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          return Center(
            child: Text(
              'No cached wallpapers found.',
              style: TextStyle(
                color: appState.isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      );
    }
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            key: const ValueKey("Cached"),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: _cachedImages.length,
            itemBuilder: (context, index) {
              final item = _cachedImages[index];
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: GestureDetector(
                  onTap:
                      () => widget.appState.wallpaperService.setWallpaper(
                        item['file'].path,
                      ),
                  onSecondaryTap: () {
                    WallpaperOptionsDialog.show(
                      context,
                      url: item['url'] ?? '',
                      canBan: false,
                      canDelete: true,
                      onFavourite:
                          item['url'] != null
                              ? widget.appState.favouriteWallpaper
                              : null,
                      onRemoveFromList: (index) {
                        _deleteCachedImage(_cachedImages[index]);
                      },
                      itemIndex: index,
                    );
                  },
                  child: Image.file(
                    item['file'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(FluentIcons.error, color: Colors.white),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(padding: EdgeInsets.all(8.0), child: ProgressRing()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Check for banned wallpapers changes and refresh if needed
        if (appState.bannedWallpapersChanged) {
          appState.resetBannedWallpapersChanged();
          // Use Future.delayed to avoid calling setState during build
          Future.delayed(Duration.zero, () => _loadCachedImages());
        }

        return PageLayout(
          description:
              'Shows cached wallpapers from AppData\\Local\\Temp\\gitwall_cache.',
          previewTitle: 'Cached Wallpaper Preview:',
          extraButtons: Row(
            children: [
              Tooltip(
                message: 'Open wallpaper cache directory',
                child: Button(
                  onPressed: _openCacheDirectory,
                  child: Icon(
                    FluentIcons.folder_open,
                    color: appState.isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NextWallpaperButton(appState: appState),
              const SizedBox(width: 8),
              ShuffleButton(appState: appState),
              const SizedBox(width: 8),
              // Custom toggle buttons for cached page (no mutual exclusion)
              Tooltip(
                message: 'Toggle favourites preview',
                child: Button(
                  onPressed: () {
                    setState(() {
                      _showFavouritesPreview = !_showFavouritesPreview;
                    });
                  },
                  child: Icon(
                    _showFavouritesPreview
                        ? FluentIcons.heart_fill
                        : FluentIcons.heart,
                    color: appState.isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Toggle banned preview',
                child: Button(
                  onPressed: () {
                    setState(() {
                      _showBannedPreview = !_showBannedPreview;
                    });
                  },
                  child: Icon(
                    _showBannedPreview
                        ? FluentIcons.block_contact
                        : FluentIcons.blocked,
                    color: appState.isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          previewContent:
              _showBannedPreview
                  ? appState.bannedWallpapersService.buildBannedPreview(
                    appState.bannedWallpapers,
                    'Multi',
                    appState,
                    setState,
                  )
                  : _showFavouritesPreview
                  ? appState.favouriteWallpapersService.buildFavouritesPreview(
                    appState.favouriteWallpapers,
                    'Multi',
                    appState,
                    setState,
                  )
                  : _buildPreviewContent(),
        );
      },
    );
  }
}
