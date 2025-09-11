import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/base_page.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../state/app_state.dart';

const rightbackgroundStartColor = Color(0xFFFFD500);
const rightbackgroundEndColor = Color(0xFFF6A00C);
const borderColor = Color(0xFF805306);

class CachedPage extends StatefulWidget {
  final AppState appState;
  const CachedPage({super.key, required this.appState});

  @override
  State<CachedPage> createState() => _CachedPageState();
}

class _CachedPageState extends State<CachedPage> {
  List<File> _cachedImages = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  late ScrollController _scrollController;
  bool _showLoadMoreButton = false;
  bool _showFavouritesPreview = false;
  bool _showBannedPreview = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadCachedImages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cached images when banned wallpapers change
    if (widget.appState.bannedWallpapersChanged) {
      widget.appState.resetBannedWallpapersChanged();
      _loadCachedImages();
    }
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_showLoadMoreButton && !_isLoading) {
        setState(() {
          _showLoadMoreButton = true;
        });
      }
    } else {
      if (_showLoadMoreButton) {
        setState(() {
          _showLoadMoreButton = false;
        });
      }
    }
  }

  void _loadCachedImages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Use AppData\Local\Temp\gitwall_cache as the cache directory
      final tempPath = Platform.environment['TEMP'];
      final cacheDir = Directory('$tempPath\\gitwall_cache');

      // Create directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Load cache metadata from gitwall_cache.json (stored in app data directory)
      final appDataDir = await getApplicationSupportDirectory();
      final cacheJsonFile = File('${appDataDir.path}\\gitwall_cache.json');
      print('DEBUG: Looking for cache JSON file at: ${cacheJsonFile.path}');
      Map<String, dynamic> cacheMetadata = {};
      if (await cacheJsonFile.exists()) {
        print('DEBUG: Found gitwall_cache.json file');
        final cacheJson = await cacheJsonFile.readAsString();
        final List<dynamic> cacheData = jsonDecode(cacheJson);
        print('DEBUG: Loaded ${cacheData.length} cache entries from JSON');
        // Convert to map by relativePath for easy lookup
        cacheMetadata = Map.fromIterable(
          cacheData,
          key: (item) => item['relativePath'] as String,
          value: (item) => item,
        );
        print('DEBUG: Cache metadata keys: ${cacheMetadata.keys.toList()}');
      } else {
        print(
          'DEBUG: gitwall_cache.json file not found at: ${cacheJsonFile.path}',
        );
      }

      final files =
          cacheDir.listSync().where((file) => file is File).cast<File>();
      // Filter to only image files
      final imageFiles =
          files.where((file) {
            final extension = file.path.split('.').last.toLowerCase();
            return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
          }).toList();

      print('DEBUG: Found ${imageFiles.length} image files in cache directory');
      print(
        'DEBUG: Image files: ${imageFiles.map((f) => p.basename(f.path)).toList()}',
      );

      // Get banned URLs from ALL tabs for direct comparison
      final allBannedWallpapers = <Map<String, String>>[];
      widget.appState.bannedWallpapers.forEach((tabKey, wallpapers) {
        allBannedWallpapers.addAll(wallpapers);
      });
      final bannedUrls =
          allBannedWallpapers.map((banned) => banned['url'] as String).toSet();

      print(
        'DEBUG: Total banned wallpapers across all tabs: ${allBannedWallpapers.length}',
      );
      for (final banned in allBannedWallpapers) {
        print(
          'DEBUG: Banned - URL: ${banned['url']} (from tab: ${widget.appState.bannedWallpapers.entries.firstWhere((entry) => entry.value.contains(banned), orElse: () => MapEntry('unknown', [])).key})',
        );
      }

      // Filter out banned wallpapers by URL comparison
      final filteredImages = <File>[];
      for (final file in imageFiles) {
        final fileName = p.basename(file.path);
        final cacheEntry = cacheMetadata[fileName];

        if (cacheEntry != null) {
          final originalUrl = cacheEntry['url'] as String;

          print('DEBUG: Processing cached file: $fileName');
          print('DEBUG: Original URL: $originalUrl');

          // Check if URL is in banned URLs set
          final isBanned = bannedUrls.contains(originalUrl);

          print('DEBUG: Is banned: $isBanned');

          if (!isBanned) {
            filteredImages.add(file);
            print('DEBUG: Including file: $fileName');
          } else {
            print('DEBUG: Filtering out banned file: $fileName');
          }
        } else {
          // Include files without metadata (fallback for compatibility)
          print(
            'DEBUG: No metadata found for file: $fileName, including as fallback',
          );
          filteredImages.add(file);
        }
      }

      print('DEBUG: Final filtered images count: ${filteredImages.length}');

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

  void _deleteCachedImage(File file) async {
    try {
      await file.delete();
      setState(() {
        _cachedImages.remove(file);
      });
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Widget _buildPreviewContent() {
    if (_cachedImages.isEmpty && _isLoading) {
      return const Center(
        child: Text('Loading...', style: TextStyle(color: Colors.white)),
      );
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error loading cached images: $_errorMessage',
              style: const TextStyle(color: Colors.white),
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
    }
    if (_cachedImages.isEmpty) {
      return const Center(
        child: Text(
          'No cached wallpapers found.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            key: const ValueKey("Cached"),
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: _cachedImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: GestureDetector(
                  onTap:
                      () => widget.appState.wallpaperService.setWallpaper(
                        _cachedImages[index].path,
                      ),
                  onSecondaryTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ContentDialog(
                          title: const Text('Delete Wallpaper'),
                          content: const Text(
                            'Are you sure you want to delete this cached wallpaper?',
                          ),
                          actions: [
                            Tooltip(
                              message: 'Delete this cached wallpaper',
                              child: Button(
                                onPressed: () {
                                  _deleteCachedImage(_cachedImages[index]);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Delete'),
                              ),
                            ),
                            Tooltip(
                              message: 'Cancel deletion',
                              child: Button(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Image.file(
                    _cachedImages[index],
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

        return Container(
          color: const Color(0xFF1F2A29),
          child: Column(
            children: [
              WindowTitleBarBox(
                child: Row(
                  children: [
                    Expanded(child: MoveWindow()),
                    const WindowButtons(),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: SizedBox(
                        height: 20,
                        child: Center(
                          child: Text(
                            'Shows cached wallpapers from AppData\\Local\\Temp\\gitwall_cache.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cached Wallpaper Preview:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Tooltip(
                                message: 'Set next wallpaper',
                                child: Button(
                                  onPressed: () => appState.setNextWallpaper(),
                                  child: const Icon(
                                    FluentIcons.next,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Toggle auto shuffle',
                                child: Button(
                                  onPressed:
                                      () => appState.toggleAutoShuffle(
                                        !appState.autoShuffleEnabled,
                                      ),
                                  child: Icon(
                                    appState.autoShuffleEnabled
                                        ? FluentIcons.repeat_all
                                        : FluentIcons.repeat_one,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Toggle favourites preview',
                                child: Button(
                                  onPressed: () {
                                    setState(() {
                                      _showFavouritesPreview =
                                          !_showFavouritesPreview;
                                    });
                                  },
                                  child: Icon(
                                    _showFavouritesPreview
                                        ? FluentIcons.heart_fill
                                        : FluentIcons.heart,
                                    color: Colors.white,
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
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 16.0,
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF2D3A3A)),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child:
                              _showBannedPreview
                                  ? appState.bannedWallpapersService
                                      .buildBannedPreview(
                                        appState.bannedWallpapers,
                                        'Multi',
                                        appState,
                                        setState,
                                      )
                                  : _showFavouritesPreview
                                  ? appState.favouriteWallpapersService
                                      .buildFavouritesPreview(
                                        appState.favouriteWallpapers,
                                        'Multi',
                                        appState,
                                        setState,
                                      )
                                  : _buildPreviewContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
