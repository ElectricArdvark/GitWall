import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/common_widgets.dart';
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
}
