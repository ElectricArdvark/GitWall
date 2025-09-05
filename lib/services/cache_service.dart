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
}
