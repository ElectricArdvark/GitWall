import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/base_page.dart';
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
    if (widget.appState.customRepoUrl.isNotEmpty && _imageUrls.isEmpty) {
      // Check internet connectivity first
      final isInternetAvailable = await widget.appState.isInternetAvailable();
      if (!isInternetAvailable) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No internet connection available';
        });
        return;
      }
      _loadImages(10);
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
      return const Center(
        child: Text(
          'Please set a custom repository URL in settings.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (_imageUrls.isEmpty && _isLoading) {
      return const Center(
        child: Text('Loading...', style: TextStyle(color: Colors.white)),
      );
    }
    if (_hasError) {
      // Special handling for no internet connection
      if (_errorMessage.contains('No internet connection available')) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No Internet Available',
                style: const TextStyle(
                  color: Colors.white,
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
      } else {
        // Regular error handling
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error loading images: $_errorMessage',
                style: const TextStyle(color: Colors.white),
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
      }
    }
    if (_imageUrls.isEmpty) {
      return const Center(
        child: Text('No images found.', style: TextStyle(color: Colors.white)),
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
                    // Show context menu for ban option
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ContentDialog(
                          title: const Text('Wallpaper Options'),
                          content: const Text(
                            'What would you like to do with this wallpaper?',
                          ),
                          actions: [
                            Tooltip(
                              message: 'Ban this wallpaper',
                              child: Button(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  final urlToBan = _imageUrls[index];
                                  // Remove from UI immediately
                                  setState(() {
                                    _imageUrls.removeAt(index);
                                  });
                                  // Then ban in background
                                  await widget.appState.banWallpaper(urlToBan);
                                },
                                child: const Text('Ban Wallpaper'),
                              ),
                            ),
                            Tooltip(
                              message: 'Add to favourites',
                              child: Button(
                                onPressed: () {
                                  widget.appState.favouriteWallpaper(
                                    _imageUrls[index],
                                  );
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Favourite'),
                              ),
                            ),
                            Tooltip(
                              message: 'Cancel',
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
                        'Uses a custom repository URL.',
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
                        'Wallpaper Preview:',
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
                                          ? FluentIcons
                                              .repeat_all //autoshuffle is on
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
                                  if (_showFavouritesPreview) {
                                    _showBannedPreview = false;
                                  }
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
                                  if (_showBannedPreview) {
                                    _showFavouritesPreview = false;
                                  }
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
                              ? widget.appState.bannedWallpapersService
                                  .buildBannedPreview(
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
}
