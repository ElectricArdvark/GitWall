import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../constants.dart';

class WallpaperDownloadResult {
  final File file;
  final String fileName;
  final String uniqueId;

  WallpaperDownloadResult(this.file, this.fileName, this.uniqueId);
}

class GitHubService {
  String _githubToken = '';
  BaseCacheManager? _cacheManager;

  void setToken(String token) {
    _githubToken = token;
  }

  void setCacheManager(BaseCacheManager cacheManager) {
    _cacheManager = cacheManager;
  }

  /// Transforms a standard GitHub repo URL to a raw content URL for a specific file.
  String getRawContentUrl(
    String repoUrl,
    String day,
    String resolution,
    String fileName,
  ) {
    // A more robust way to parse various GitHub URL formats
    final uri = Uri.parse(repoUrl);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (pathSegments.length < 2) {
      throw ArgumentError(
        'Invalid GitHub repository URL. Expected format: https://github.com/user/repo',
      );
    }

    final user = pathSegments[0];
    final repo = pathSegments[1];

    // Assume the 'main' branch. A future improvement could be to detect the default branch.
    String basePath = 'https://raw.githubusercontent.com/$user/$repo/main';
    if (repoUrl == defaultRepoUrl) {
      if (day.isEmpty) {
        // For Multi, since effectiveDay is set to empty string
        return '$basePath/Multi/$resolution/$fileName';
      } else {
        return '$basePath/Weekly/$day/$fileName';
      }
    } else if (repoUrl.contains('Multi')) {
      return '$basePath/Multi/$resolution/$fileName';
    } else {
      return '$basePath/$fileName';
    }
  }

  /// Fetches a list of raw image URLs from the repository
  Future<List<String>> getImageUrls(
    String repoUrl,
    String resolution,
    String day,
    int limit, {
    int offset = 0,
  }) async {
    print('DEBUG: getImageUrls called with:');
    print('DEBUG: repoUrl: $repoUrl');
    print('DEBUG: resolution: $resolution');
    print('DEBUG: day: $day');
    print('DEBUG: limit: $limit');
    print('DEBUG: offset: $offset');

    String subPath;
    if (repoUrl == defaultRepoUrl && day.toLowerCase() == 'multi') {
      subPath = 'Multi/$resolution';
      print('DEBUG: Using subPath for Multi: $subPath');
    } else {
      subPath = ''; // Root for custom
      print('DEBUG: Using root path for Custom');
    }

    print(
      'DEBUG: Fetching repository contents from: $repoUrl, subPath: $subPath',
    );
    final allFiles = await _fetchRepositoryContents(repoUrl, subPath);
    print('DEBUG: All files fetched: ${allFiles.length}');
    for (var i = 0; i < allFiles.length && i < 10; i++) {
      print('DEBUG: File $i: ${allFiles[i]}');
    }

    final imageFiles =
        allFiles.where((file) {
          return supportedImageExtensions.any(
            (ext) => file.toLowerCase().endsWith(ext),
          );
        }).toList();

    print('DEBUG: Image files found: ${imageFiles.length}');
    for (var i = 0; i < imageFiles.length && i < 10; i++) {
      print('DEBUG: Image file $i: ${imageFiles[i]}');
    }

    final limitedFiles = imageFiles.skip(offset).take(limit).toList();
    print(
      'DEBUG: Limited files (offset: $offset, limit: $limit): ${limitedFiles.length}',
    );

    final uri = Uri.parse(repoUrl);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final user = pathSegments[0];
    final repo = pathSegments[1];
    final baseUrl = 'https://raw.githubusercontent.com/$user/$repo/main';
    print('DEBUG: Base URL: $baseUrl');

    List<String> urls = [];
    for (final file in limitedFiles) {
      String url;
      if (subPath.isNotEmpty) {
        url = '$baseUrl/$subPath/$file';
      } else {
        url = '$baseUrl/$file';
      }
      urls.add(url);
      print('DEBUG: Generated URL: $url');
    }

    print('DEBUG: Total URLs generated: ${urls.length}');
    return urls;
  }

  Future<List<String>> _fetchRepositoryContents(
    String repoUrl, [
    String? subPath,
  ]) async {
    print('DEBUG: _fetchRepositoryContents called with:');
    print('DEBUG: repoUrl: $repoUrl');
    print('DEBUG: subPath: $subPath');

    final uri = Uri.parse(repoUrl);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (pathSegments.length < 2) {
      throw ArgumentError(
        'Invalid GitHub repository URL. Expected format: https://github.com/user/repo',
      );
    }

    final user = pathSegments[0];
    final repo = pathSegments[1];

    String contentsUrl = 'https://api.github.com/repos/$user/$repo/contents';
    if (subPath != null && subPath.isNotEmpty) {
      contentsUrl += '/$subPath';
    }

    print('DEBUG: GitHub API URL: $contentsUrl');

    final headers =
        _githubToken.isNotEmpty
            ? <String, String>{'Authorization': 'token $_githubToken'}
            : <String, String>{};

    print('DEBUG: Using GitHub token: ${_githubToken.isNotEmpty}');

    try {
      print('DEBUG: Making HTTP request to GitHub API...');
      final response = await http.get(Uri.parse(contentsUrl), headers: headers);
      print('DEBUG: GitHub API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        print('DEBUG: JSON response contains ${jsonResponse.length} items');

        final files =
            jsonResponse
                .where((item) => item['type'] == 'file')
                .map<String>((item) => item['name'] as String)
                .toList();

        print('DEBUG: Found ${files.length} files');
        return files;
      } else {
        print('DEBUG: GitHub API error response: ${response.body}');
        throw Exception(
          'Failed to fetch repository contents: ${response.statusCode} - $contentsUrl',
        );
      }
    } catch (e) {
      print('DEBUG: Exception in _fetchRepositoryContents: $e');
      throw Exception('$e');
    }
  }

  /// Generates a unique identifier for a wallpaper based on its source
  String _generateWallpaperUniqueId(
    String repoUrl,
    String day,
    String resolution,
    String fileName,
  ) {
    // Create a hash of the repo URL, day, resolution, and filename to create a unique ID
    final sourceKey = '$repoUrl|$day|$resolution|$fileName';
    // Use a simple hash function for the unique ID
    final hashCode = sourceKey.hashCode.abs();
    return 'wallpaper_${hashCode.toString()}';
  }

  /// Downloads the wallpaper image bytes from the constructed raw URL.
  Future<WallpaperDownloadResult> downloadWallpaper(
    String repoUrl,
    String day,
    String resolution,
    String extension, {
    String? customFileName,
  }) async {
    String fileName;
    String effectiveDay = day;
    String effectiveResolution = resolution;

    if (repoUrl == defaultRepoUrl && day.toLowerCase() == 'multi') {
      final allFiles = await _fetchRepositoryContents(
        repoUrl,
        'Multi/$resolution',
      );
      final imageFiles =
          allFiles.where((file) {
            return supportedImageExtensions.any(
              (ext) => file.toLowerCase().endsWith(ext),
            );
          }).toList();

      if (imageFiles.isEmpty) {
        throw Exception('No supported image files found in the repository.');
      }

      final randomIndex = Random().nextInt(imageFiles.length);
      fileName = imageFiles[randomIndex];

      effectiveDay = '';
    } else if (repoUrl == defaultRepoUrl) {
      fileName = '${day}_$resolution$extension';
    } else if (repoUrl.contains('Multi')) {
      final allFiles = await _fetchRepositoryContents(
        repoUrl,
        'Multi/$resolution',
      );
      final imageFiles =
          allFiles.where((file) {
            return supportedImageExtensions.any(
              (ext) => file.toLowerCase().endsWith(ext),
            );
          }).toList();

      if (imageFiles.isEmpty) {
        throw Exception('No supported image files found in the repository.');
      }

      final randomIndex = Random().nextInt(imageFiles.length);
      fileName = imageFiles[randomIndex];

      effectiveDay = '';
    } else {
      final allFiles = await _fetchRepositoryContents(repoUrl);
      final imageFiles =
          allFiles.where((file) {
            return supportedImageExtensions.any(
              (ext) => file.toLowerCase().endsWith(ext),
            );
          }).toList();

      if (imageFiles.isEmpty) {
        throw Exception('No supported image files found in the repository.');
      }

      final randomIndex = Random().nextInt(imageFiles.length);
      fileName = imageFiles[randomIndex];
      effectiveDay = '';
      effectiveResolution = '';
    }

    final url = getRawContentUrl(
      repoUrl,
      effectiveDay,
      effectiveResolution,
      fileName,
    );

    // Generate unique identifier for this wallpaper
    final uniqueId = _generateWallpaperUniqueId(
      repoUrl,
      effectiveDay,
      effectiveResolution,
      fileName,
    );

    try {
      final cacheManager = _cacheManager ?? DefaultCacheManager();
      final file = await cacheManager.getSingleFile(url);
      return WallpaperDownloadResult(file, fileName, uniqueId);
    } catch (e) {
      throw Exception('Failed to download or cache image: $e');
    }
  }
}
