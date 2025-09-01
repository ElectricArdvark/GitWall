import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../constants.dart';

class WallpaperDownloadResult {
  final http.Response response;
  final String fileName;

  WallpaperDownloadResult(this.response, this.fileName);
}

class GitHubService {
  /// Transforms a standard GitHub repo URL to a raw content URL for a specific file.
  String getRawContentUrl(String repoUrl, String day, String fileName) {
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
      return '$basePath/Weekly/$day/$fileName';
    } else {
      return '$basePath/$fileName';
    }
  }

  Future<List<String>> _fetchRepositoryContents(String repoUrl) async {
    final uri = Uri.parse(repoUrl);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (pathSegments.length < 2) {
      throw ArgumentError(
        'Invalid GitHub repository URL. Expected format: https://github.com/user/repo',
      );
    }

    final user = pathSegments[0];
    final repo = pathSegments[1];

    final contentsUrl = 'https://api.github.com/repos/$user/$repo/contents/';
    try {
      final response = await http.get(Uri.parse(contentsUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse
            .where((item) => item['type'] == 'file')
            .map<String>((item) => item['name'] as String)
            .toList();
      } else {
        throw Exception(
          'Failed to fetch repository contents: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect or fetch repository contents: $e');
    }
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

    if (repoUrl == defaultRepoUrl) {
      fileName = '${day}_$resolution$extension';
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
    }

    final url = getRawContentUrl(repoUrl, effectiveDay, fileName);

    try {
      final response = await http.get(Uri.parse(url));
      return WallpaperDownloadResult(response, fileName);
    } catch (e) {
      throw Exception('Failed to connect or download image: $e');
    }
  }
}
