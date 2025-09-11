import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/base_page.dart';
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
                        'Uses the default repository for weekly wallpapers.',
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
                              ? _buildBannedPreview()
                              : _showFavouritesPreview
                              ? _buildFavouritesPreview()
                              : _buildCurrentWallpaperPreview(),
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

  Widget _buildCurrentWallpaperPreview() {
    return widget.appState.currentWallpaperFile != null &&
            widget.appState.currentWallpaperFile!.existsSync()
        ? Image.file(
          widget.appState.currentWallpaperFile!,
          fit: BoxFit.fill,
          key: ValueKey(widget.appState.currentWallpaperFile!.path),
        )
        : const Center(
          child: Text(
            'No wallpaper preview available.',
            style: TextStyle(color: Colors.white),
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
