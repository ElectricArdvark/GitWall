import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CacheService {
  String? _customWallpaperLocation;

  void setCustomWallpaperLocation(String? location) {
    _customWallpaperLocation = location;
  }

  Future<String> get _localPath async {
    if (_customWallpaperLocation != null &&
        _customWallpaperLocation!.isNotEmpty) {
      // Use custom location if set
      final cachePath = p.join(
        _customWallpaperLocation!,
        'GitWall',
        'Wallpapers',
      );
      await Directory(cachePath).create(recursive: true);
      return cachePath;
    } else {
      // Default location
      final directory = await getApplicationSupportDirectory();
      // Create a dedicated directory for GitWall wallpapers
      final cachePath = p.join(directory.path, 'GitWall', 'Wallpapers');
      await Directory(cachePath).create(recursive: true);
      return cachePath;
    }
  }

  Future<String> get _cacheIndexPath async {
    final cachePath = await _localPath;
    return p.join(cachePath, 'cache_index.json');
  }

  Future<File> getLocalFile(String fileName) async {
    final path = await _localPath;
    return File(p.join(path, fileName));
  }

  Future<File> saveFile(String fileName, List<int> bytes) async {
    final file = await getLocalFile(fileName);
    return file.writeAsBytes(bytes);
  }

  /// Checks if a wallpaper with the given unique ID is already cached
  Future<bool> isWallpaperCached(String uniqueId) async {
    final cacheIndex = await _loadCacheIndex();
    return cacheIndex.containsKey(uniqueId);
  }

  /// Gets cached wallpaper file for a unique ID
  Future<File?> getCachedWallpaper(String uniqueId) async {
    final cacheIndex = await _loadCacheIndex();
    final fileName = cacheIndex[uniqueId];
    if (fileName != null) {
      final file = await getLocalFile(fileName);
      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  /// Saves wallpaper with unique ID mapping
  Future<File> saveWallpaperWithId(
    String uniqueId,
    String originalFileName,
    List<int> bytes,
  ) async {
    // Check if this wallpaper is already cached
    final cachedFile = await getCachedWallpaper(uniqueId);
    if (cachedFile != null) {
      // Return existing cached file
      return cachedFile;
    }

    // Create a unique cache file name for new wallpaper
    final cacheFileName =
        '${uniqueId}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = await saveFile(cacheFileName, bytes);

    // Update cache index
    final cacheIndex = await _loadCacheIndex();
    cacheIndex[uniqueId] = cacheFileName;
    await _saveCacheIndex(cacheIndex);

    return file;
  }

  Future<Map<String, String>> _loadCacheIndex() async {
    final indexPath = await _cacheIndexPath;
    final indexFile = File(indexPath);

    if (await indexFile.exists()) {
      final content = await indexFile.readAsString();
      final Map<String, dynamic> jsonData = json.decode(content);
      return jsonData.map((key, value) => MapEntry(key, value as String));
    }

    return {};
  }

  Future<void> _saveCacheIndex(Map<String, String> index) async {
    final indexPath = await _cacheIndexPath;
    final content = json.encode(index);
    await File(indexPath).writeAsString(content);
  }

  /// Clears old cached wallpapers (keeping only the most recent ones)
  Future<void> cleanupOldCache({int maxFiles = 50}) async {
    final cacheIndex = await _loadCacheIndex();
    final path = await _localPath;

    if (cacheIndex.length <= maxFiles) return;

    // Sort by modification time (newest first)
    final files = await Directory(path).list().toList();
    files.sort((a, b) {
      if (a is File && b is File) {
        return b.statSync().modified.compareTo(a.statSync().modified);
      }
      return 0;
    });

    // Keep only the most recent files
    for (int i = maxFiles; i < files.length; i++) {
      if (files[i] is File && !files[i].path.endsWith('cache_index.json')) {
        await files[i].delete();
      }
    }
  }

  /// Gets the most recent cached wallpaper file
  Future<File?> getMostRecentCachedWallpaper() async {
    final cacheIndex = await _loadCacheIndex();
    if (cacheIndex.isEmpty) return null;

    final path = await _localPath;
    List<File> files = [];
    for (final fileName in cacheIndex.values) {
      final file = File(p.join(path, fileName));
      if (await file.exists()) {
        files.add(file);
      }
    }

    if (files.isEmpty) return null;

    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files.first;
  }

  /// Gets all cached wallpapers for a specific tab based on unique ID pattern
  Future<List<File>> getCachedWallpapersForTab(String tabIdentifier) async {
    final cacheIndex = await _loadCacheIndex();
    if (cacheIndex.isEmpty) return [];

    final path = await _localPath;
    List<File> matchingFiles = [];

    for (final entry in cacheIndex.entries) {
      final fileName = entry.value;

      final file = File(p.join(path, fileName));
      if (await file.exists()) {
        matchingFiles.add(file);
      }
    }

    return matchingFiles;
  }

  /// Gets a random cached wallpaper for a specific tab, excluding used ones
  Future<File?> getRandomCachedWallpaperForTab(
    String tabIdentifier,
    List<String> usedWallpaperIds,
  ) async {
    final cachedFiles = await getCachedWallpapersForTab(tabIdentifier);
    if (cachedFiles.isEmpty) return null;

    // Load cache index once
    final cacheIndex = await _loadCacheIndex();

    // Filter out used wallpapers
    final availableFiles =
        cachedFiles.where((file) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          // Find the unique ID for this file
          final uniqueId =
              cacheIndex.entries
                  .firstWhere(
                    (entry) => entry.value == fileName,
                    orElse: () => MapEntry('', ''),
                  )
                  .key;

          return uniqueId.isNotEmpty && !usedWallpaperIds.contains(uniqueId);
        }).toList();

    if (availableFiles.isEmpty) {
      // All wallpapers are used, return a random one from all cached files
      // This simulates the reset behavior from online cycling
      cachedFiles.shuffle();
      return cachedFiles.first;
    }

    // Return random available file
    availableFiles.shuffle();
    return availableFiles.first;
  }

  /// Gets the unique ID for a cached file based on its filename
  Future<String?> getUniqueIdForCachedFile(String fileName) async {
    final cacheIndex = await _loadCacheIndex();
    return cacheIndex.entries
        .firstWhere(
          (entry) => entry.value == fileName,
          orElse: () => MapEntry('', ''),
        )
        .key;
  }
}
