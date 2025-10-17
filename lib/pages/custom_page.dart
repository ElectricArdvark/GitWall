import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/widgets/common_widget.dart';
import 'package:gitwall/buttons/next_wallpaper_button.dart';
import 'package:gitwall/buttons/shuffle_button.dart';
import 'package:gitwall/widgets/wallpaper_options_widget.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

const rightbackgroundStartColor = Color(0xFFFFD500);
const rightbackgroundEndColor = Color(0xFFF6A00C);
const borderColor = Color(0xFF805306);

class CustomPage extends StatefulWidget {
  final AppState appState;
  const CustomPage({super.key, required this.appState});

  @override
  State<CustomPage> createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  List<String> _imageUrls = [];
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
    _fetchUrlsIfNeeded();
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
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

  void _onAppStateChanged() {
    if (widget.appState.bannedWallpapersChanged) {
      // Re-fetch images if the banned list changes
      _imageUrls = [];
      _fetchUrlsIfNeeded();
      widget.appState.resetBannedWallpapersChanged();
    }
  }

  @override
  void didUpdateWidget(covariant CustomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState.customRepoUrl != widget.appState.customRepoUrl ||
        oldWidget.appState.currentResolution !=
            widget.appState.currentResolution) {
      setState(() {
        _imageUrls = [];
        _hasError = false;
        _errorMessage = '';
      });
      _fetchUrlsIfNeeded();
    }
  }

  void _fetchUrlsIfNeeded() async {
    if (_imageUrls.isEmpty) {
      // First, try to load cached wallpapers
      await _loadCachedImages();

      // Then check internet connectivity and load additional images
      final isInternetAvailable = await widget.appState.isInternetAvailable();
      if (!isInternetAvailable) {
        // If no internet and no cached images, show error
        if (_imageUrls.isEmpty) {
          setState(() {
            _hasError = true;
            _errorMessage = 'No internet connection available';
          });
        }
        return;
      }
      _loadImages(10);
    }
  }

  Future<void> _loadCachedImages() async {
    try {
      final repoUrl = widget.appState.customRepoUrl;
      const day = '';
      final resolution = widget.appState.currentResolution;

      // Get cached wallpaper URLs for this repository
      final cachedUrls = await widget.appState.getCachedWallpaperUrls(
        repoUrl,
        day,
        resolution,
      );

      // Filter out banned wallpapers
      final banned = widget.appState.bannedWallpapers['Multi'] ?? [];
      final filteredCachedUrls =
          cachedUrls.where((url) {
            final uri = Uri.parse(url);
            final fileName = uri.pathSegments.last;
            final uniqueId = widget.appState.generateWallpaperUniqueId(
              repoUrl,
              '',
              widget.appState.currentResolution,
              fileName,
            );
            return !banned.any(
              (bannedWallpaper) => bannedWallpaper['uniqueId'] == uniqueId,
            );
          }).toList();

      if (filteredCachedUrls.isNotEmpty) {
        setState(() {
          _imageUrls.addAll(filteredCachedUrls);
        });
      }
    } catch (e) {
      // Ignore cache loading errors - we'll still try to load from online
      print('Error loading cached images: $e');
    }
  }

  void _loadImages(int count, {int offset = 0}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final repoUrl = widget.appState.customRepoUrl;
      final day = '';
      final allUrls = await widget.appState.githubService.getImageUrls(
        repoUrl,
        widget.appState.currentResolution,
        day,
        count * 2, // Get more to account for banned ones
        offset: offset,
      );

      // Filter out banned wallpapers
      final banned = widget.appState.bannedWallpapers['Multi'] ?? [];
      final filteredUrls =
          allUrls
              .where((url) {
                final uri = Uri.parse(url);
                final fileName = uri.pathSegments.last;
                final uniqueId = widget.appState.generateWallpaperUniqueId(
                  repoUrl,
                  '',
                  widget.appState.currentResolution,
                  fileName,
                );
                return !banned.any(
                  (bannedWallpaper) => bannedWallpaper['uniqueId'] == uniqueId,
                );
              })
              .take(count)
              .toList();

      setState(() {
        _imageUrls.addAll(filteredUrls);
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

  void _loadMore() => _loadImages(10, offset: _imageUrls.length);

  Widget _buildPreviewContent() {
    if (widget.appState.customRepoUrl.isEmpty) {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          return Center(
            child: Text(
              'Please set a custom repository URL in settings.',
              style: TextStyle(
                color: appState.isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      );
    }
    if (_imageUrls.isEmpty && _isLoading) {
      return const LoadingWidget();
    }
    if (_hasError) {
      // Special handling for no internet connection
      if (_errorMessage.contains('No internet connection available')) {
        return Consumer<AppState>(
          builder: (context, appState, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No Internet Available',
                    style: TextStyle(
                      color: appState.isDarkTheme ? Colors.white : Colors.black,
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
                    message: 'Retry loading images',
                    child: Button(
                      onPressed: () => _fetchUrlsIfNeeded(),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // Regular error handling
        return Consumer<AppState>(
          builder: (context, appState, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading images: $_errorMessage',
                    style: TextStyle(
                      color: appState.isDarkTheme ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: 'Retry loading images',
                    child: Button(
                      onPressed: () => _loadImages(10),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
    if (_imageUrls.isEmpty) {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          return Center(
            child: Text(
              'No images found.',
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
            key: const ValueKey("Multi"),
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: GestureDetector(
                  onTap:
                      () =>
                          widget.appState.setWallpaperForUrl(_imageUrls[index]),
                  onSecondaryTap: () {
                    WallpaperOptionsDialog.show(
                      context,
                      url: _imageUrls[index],
                      onBan: widget.appState.banWallpaper,
                      onFavourite: widget.appState.favouriteWallpaper,
                      onRemoveFromList: (index) {
                        setState(() {
                          _imageUrls.removeAt(index);
                        });
                      },
                      itemIndex: index,
                    );
                  },
                  child: FutureBuilder<File?>(
                    future: widget.appState.customCacheManager
                        .getFileFromCache(_imageUrls[index])
                        .then((info) => info?.file),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        // Use cached file directly
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            snapshot.data!,
                            key: ValueKey(_imageUrls[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  FluentIcons.error,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        // Use network image (will use cache if available)
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _imageUrls[index],
                            key: ValueKey(_imageUrls[index]),
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
                                child: Icon(
                                  FluentIcons.error,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(padding: EdgeInsets.all(8.0), child: ProgressRing())
        else if (_showLoadMoreButton)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Tooltip(
              message: 'Load more wallpapers',
              child: Button(
                onPressed: _loadMore,
                child: const Text('Load More'),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      description: 'Uses a custom repository URL.',
      previewTitle: 'Wallpaper Preview:',
      extraButtons: Consumer<AppState>(
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
      ),
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
              : _buildPreviewContent(),
      onToggleChanged: (favourites, banned) {
        setState(() {
          _showFavouritesPreview = favourites;
          _showBannedPreview = banned;
        });
      },
    );
  }
}
