import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/home_page.dart';
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
  Future<List<String>>? _imageUrlsFuture;

  @override
  void initState() {
    super.initState();
    _fetchUrlsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CustomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState.customRepoUrl != widget.appState.customRepoUrl ||
        oldWidget.appState.currentResolution !=
            widget.appState.currentResolution) {
      _fetchUrlsIfNeeded();
    }
  }

  void _fetchUrlsIfNeeded() {
    if (widget.appState.customRepoUrl.isNotEmpty) {
      setState(() {
        _imageUrlsFuture = _fetchImageUrls();
      });
    } else {
      setState(() {
        _imageUrlsFuture = null;
      });
    }
  }

  Future<List<String>> _fetchImageUrls() async {
    final repoUrl = widget.appState.customRepoUrl;
    final day = '';
    return await widget.appState.githubService.getImageUrls(
      repoUrl,
      widget.appState.currentResolution,
      day,
      10,
    );
  }

  Widget _buildPreviewContent() {
    if (widget.appState.customRepoUrl.isEmpty) {
      return const Center(
        child: Text(
          'Please set a custom repository URL in settings.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (_imageUrlsFuture == null) {
      return const Center(
        child: Text('Loading...', style: TextStyle(color: Colors.white)),
      );
    }
    return FutureBuilder<List<String>>(
      future: _imageUrlsFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Text(
              'Loading images...',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No images found.',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          final urls = snapshot.data!;
          return GridView.builder(
            key: ValueKey("Custom_${DateTime.now().millisecondsSinceEpoch}"),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: GestureDetector(
                  onTap: () => widget.appState.setWallpaperForUrl(urls[index]),
                  child: Image.network(
                    urls[index],
                    key: ValueKey(urls[index]),
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
      },
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
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Text(
                    'Wallpaper Preview:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF2D3A3A)),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: _buildPreviewContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 10.0,
              top: 8.0,
            ),
            child: Row(
              children: [
                if (!widget.appState.hideStatus)
                  Text(
                    'Status: ${widget.appState.status}',
                    style: const TextStyle(color: Colors.white),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed:
                      () => widget.appState.updateWallpaper(isManual: true),
                  child: const Text('Force Refresh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
