import 'package:http/http.dart' as http;

class GitHubService {
  /// Transforms a standard GitHub repo URL to a raw content URL for a specific file.
  String getRawContentUrl(String repoUrl, String fileName) {
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
    return 'https://raw.githubusercontent.com/$user/$repo/main/$fileName';
  }

  /// Downloads the wallpaper image bytes from the constructed raw URL.
  Future<http.Response> downloadWallpaper(
    String repoUrl,
    String day,
    String resolution,
    String extension,
  ) async {
    final fileName = '$day$resolution$extension';
    final url = getRawContentUrl(repoUrl, fileName);

    try {
      final response = await http.get(Uri.parse(url));
      return response;
    } catch (e) {
      throw Exception('Failed to connect or download image: $e');
    }
  }
}
