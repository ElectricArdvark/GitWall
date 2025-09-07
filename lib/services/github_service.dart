import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../constants.dart';

class WallpaperDownloadResult {
  final http.Response response;
  final String fileName;
  final String uniqueId;

  WallpaperDownloadResult(this.response, this.fileName, this.uniqueId);
}

class GitHubService {
  String _githubToken = '';

  void setToken(String token) {
    _githubToken = token;
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
    int limit,
  ) async {
    String subPath;
    if (repoUrl == defaultRepoUrl && day.toLowerCase() == 'multi') {
      subPath = 'Multi/$resolution';
    } else {
      subPath = ''; // Root for custom
    }

    final allFiles = await _fetchRepositoryContents(repoUrl, subPath);
    final imageFiles =
        allFiles.where((file) {
          return supportedImageExtensions.any(
            (ext) => file.toLowerCase().endsWith(ext),
          );
        }).toList();

    final limitedFiles = imageFiles.take(limit).toList();

    final uri = Uri.parse(repoUrl);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final user = pathSegments[0];
    final repo = pathSegments[1];
    final baseUrl = 'https://raw.githubusercontent.com/$user/$repo/main';

    List<String> urls = [];
    for (final file in limitedFiles) {
      if (subPath.isNotEmpty) {
        urls.add('$baseUrl/$subPath/$file');
      } else {
        urls.add('$baseUrl/$file');
      }
    }

    return urls;
  }

  Future<List<String>> _fetchRepositoryContents(
    String repoUrl, [
    String? subPath,
  ]) async {
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

    final headers =
        _githubToken.isNotEmpty
            ? <String, String>{'Authorization': 'token $_githubToken'}
            : <String, String>{};

    try {
      final response = await http.get(Uri.parse(contentsUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final files =
            jsonResponse
                .where((item) => item['type'] == 'file')
                .map<String>((item) => item['name'] as String)
                .toList();

        return files;
      } else {
        throw Exception(
          'Failed to fetch repository contents: ${response.statusCode} - $contentsUrl',
        );
      }
    } catch (e) {
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
      final response = await http.get(Uri.parse(url));
      return WallpaperDownloadResult(response, fileName, uniqueId);
    } catch (e) {
      throw Exception('Failed to connect or download image: $e');
    }
  }
}
