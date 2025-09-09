import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:gitwall/ui/base_page.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

const rightbackgroundStartColor = Color(0xFFFFD500);
const rightbackgroundEndColor = Color(0xFFF6A00C);
const borderColor = Color(0xFF805306);

class MultiPage extends StatefulWidget {
  final AppState appState;
  const MultiPage({super.key, required this.appState});

  @override
  State<MultiPage> createState() => _MultiPageState();
}

class _MultiPageState extends State<MultiPage> {
  Future<List<String>>? _imageUrlsFuture;

  @override
  void initState() {
    super.initState();
    _fetchUrlsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MultiPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState.repoUrl != widget.appState.repoUrl) {
      _fetchUrlsIfNeeded();
    }
  }

  void _fetchUrlsIfNeeded() {
    setState(() {
      _imageUrlsFuture = _fetchImageUrls();
    });
  }

  Future<List<String>> _fetchImageUrls() async {
    final repoUrl = widget.appState.repoUrl;
    const day = 'multi';
    return await widget.appState.githubService.getImageUrls(
      repoUrl.isEmpty
          ? 'https://github.com/ElectricArdvark/wallpapers'
          : repoUrl,
      widget.appState.currentResolution,
      day,
      10,
    );
  }

  Widget _buildPreviewContent() {
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
            key: ValueKey("Multi_${DateTime.now().millisecondsSinceEpoch}"),
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
                        'Uses a repository with multiple resolutions.',
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
                      Consumer<AppState>(
                        builder:
                            (context, appState, child) => Button(
                              onPressed:
                                  () => appState.toggleAutoShuffle(
                                    !appState.autoShuffleEnabled,
                                  ),
                              child: Icon(
                                appState.autoShuffleEnabled
                                    ? FluentIcons
                                        .repeat_all //autoshuffle is on
                                    : FluentIcons
                                        .repeat_one, //autoshuffle is on
                                color: Colors.white,
                              ),
                            ),
                      ),
                    ],
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
        ],
      ),
    );
  }
}
