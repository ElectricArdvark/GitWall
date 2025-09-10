import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/base_page.dart';
import 'package:provider/provider.dart';
import 'dart:io';
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

      final files =
          cacheDir.listSync().where((file) => file is File).cast<File>();
      // Filter to only image files
      final imageFiles =
          files.where((file) {
            final extension = file.path.split('.').last.toLowerCase();
            return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
          }).toList();
      setState(() {
        _cachedImages = imageFiles;
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
    return Container(
      color: const Color(0xFF1F2A29),
      child: Column(
        children: [
          WindowTitleBarBox(
            child: Row(
              children: [Expanded(child: MoveWindow()), const WindowButtons()],
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
                          Consumer<AppState>(
                            builder:
                                (context, appState, child) => Tooltip(
                                  message: 'Set next wallpaper',
                                  child: Button(
                                    onPressed:
                                        () => appState.setNextWallpaper(),
                                    child: const Icon(
                                      FluentIcons.next,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Consumer<AppState>(
                            builder:
                                (context, appState, child) => Tooltip(
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
                              ? _buildBannedPreview()
                              : _showFavouritesPreview
                              ? _buildFavouritesPreview()
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
  }

  Widget _buildFavouritesPreview() {
    final favourites = widget.appState.favouriteWallpapers['Multi'] ?? [];
    if (favourites.isEmpty) {
      return const Center(
        child: Text(
          'No favourite wallpapers yet.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return GridView.builder(
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
            onTap: () => widget.appState.setWallpaperForUrl(favourite['url']!),
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
                            widget.appState.unfavouriteWallpaper(
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
            child: Image.network(
              favourite['url']!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(FluentIcons.error, color: Colors.white),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannedPreview() {
    final banned = widget.appState.bannedWallpapers['Multi'] ?? [];
    if (banned.isEmpty) {
      return const Center(
        child: Text(
          'No banned wallpapers yet.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
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
                () =>
                    widget.appState.setWallpaperForUrl(bannedWallpaper['url']!),
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
                            widget.appState.unbanWallpaper(
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
                return const Center(
                  child: Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(FluentIcons.error, color: Colors.white),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
