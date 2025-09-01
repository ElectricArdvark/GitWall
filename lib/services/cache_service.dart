import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CacheService {
  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    // Create a dedicated directory for GitWall wallpapers
    final cachePath = p.join(directory.path, 'GitWall', 'Wallpapers');
    await Directory(cachePath).create(recursive: true);
    return cachePath;
  }

  Future<File> getLocalFile(String fileName) async {
    final path = await _localPath;
    return File(p.join(path, fileName));
  }

  Future<File> saveFile(String fileName, List<int> bytes) async {
    final file = await getLocalFile(fileName);
    return file.writeAsBytes(bytes);
  }
}
