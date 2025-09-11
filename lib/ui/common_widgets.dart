import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;

var buttonColors = WindowButtonColors(
  iconNormal: const Color(0xFFFFFFFF),
  mouseOver: const Color(0xFF2D3A3A),
  mouseDown: const Color(0xFF1F2A29),
  iconMouseOver: const Color(0xFFFFFFFF),
  iconMouseDown: const Color(0xFFFFFFFF),
);

var closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFFFFFFFF),
  iconMouseOver: const Color(0xFFFFFFFF),
);

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Minimize',
          child: MinimizeWindowButton(colors: buttonColors),
        ),
        Tooltip(
          message: 'Maximize',
          child: MaximizeWindowButton(colors: buttonColors),
        ),
        Tooltip(
          message: 'Close',
          child: CloseWindowButton(colors: closeButtonColors),
        ),
      ],
    );
  }
}

// Common page layout widget
class PageLayout extends StatelessWidget {
  final String description;
  final String previewTitle;
  final Widget? extraButtons;
  final Widget previewContent;
  final Function(bool, bool)? onToggleChanged;

  const PageLayout({
    super.key,
    required this.description,
    required this.previewTitle,
    this.extraButtons,
    required this.previewContent,
    this.onToggleChanged,
  });

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
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: SizedBox(
                    height: 20,
                    child: Center(
                      child: Text(
                        description,
                        style: const TextStyle(color: Colors.white),
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
                      Text(
                        previewTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          if (extraButtons != null) extraButtons!,
                          if (onToggleChanged != null)
                            ToggleButtons(onToggleChanged: onToggleChanged!),
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
                      child: previewContent,
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

// Toggle buttons for favourites and banned previews
class ToggleButtons extends StatefulWidget {
  final Function(bool, bool) onToggleChanged;

  const ToggleButtons({super.key, required this.onToggleChanged});

  @override
  State<ToggleButtons> createState() => _ToggleButtonsState();
}

class _ToggleButtonsState extends State<ToggleButtons> {
  bool _showFavouritesPreview = false;
  bool _showBannedPreview = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Toggle favourites preview',
          child: Button(
            onPressed: () {
              setState(() {
                _showFavouritesPreview = !_showFavouritesPreview;
                if (_showFavouritesPreview) {
                  _showBannedPreview = false;
                }
                widget.onToggleChanged(
                  _showFavouritesPreview,
                  _showBannedPreview,
                );
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
                widget.onToggleChanged(
                  _showFavouritesPreview,
                  _showBannedPreview,
                );
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
    );
  }
}

// Common loading widget
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Loading...', style: TextStyle(color: Colors.white)),
    );
  }
}

// Common error widget
class ErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorWidget({super.key, required this.errorMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            Tooltip(
              message: 'Retry',
              child: Button(onPressed: onRetry, child: const Text('Retry')),
            ),
          ],
        ],
      ),
    );
  }
}

// Common no data widget
class NoDataWidget extends StatelessWidget {
  final String message;

  const NoDataWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}

// Common wallpaper grid widget
class WallpaperGrid extends StatelessWidget {
  final List<String> imageUrls;
  final Function(String) onTap;
  final Function(int) onSecondaryTap;
  final ScrollController? controller;
  final bool showLoadMore;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  const WallpaperGrid({
    super.key,
    required this.imageUrls,
    required this.onTap,
    required this.onSecondaryTap,
    this.controller,
    this.showLoadMore = false,
    this.onLoadMore,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            key: const ValueKey("WallpaperGrid"),
            controller: controller,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: GestureDetector(
                  onTap: () => onTap(imageUrls[index]),
                  onSecondaryTap: () => onSecondaryTap(index),
                  child: Image.network(
                    imageUrls[index],
                    key: ValueKey(imageUrls[index]),
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
        if (isLoading)
          const Padding(padding: EdgeInsets.all(8.0), child: ProgressRing())
        else if (showLoadMore)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Tooltip(
              message: 'Load more wallpapers',
              child: Button(
                onPressed: onLoadMore,
                child: const Text('Load More'),
              ),
            ),
          ),
      ],
    );
  }
}

// Common wallpaper context menu
void showWallpaperContextMenu(
  BuildContext context,
  String url,
  Function(String) onBan,
  Function(String) onFavourite,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ContentDialog(
        title: const Text('Wallpaper Options'),
        content: const Text('What would you like to do with this wallpaper?'),
        actions: [
          Tooltip(
            message: 'Ban this wallpaper',
            child: Button(
              onPressed: () async {
                Navigator.of(context).pop();
                onBan(url);
              },
              child: const Text('Ban Wallpaper'),
            ),
          ),
          Tooltip(
            message: 'Add to favourites',
            child: Button(
              onPressed: () {
                onFavourite(url);
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
}
