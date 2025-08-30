import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WallpaperService {
  /// Sets the Windows desktop wallpaper to the image at the given path.
  void setWallpaper(String imagePath) {
    // SPI_SETDESKWALLPAPER = 0x0014
    // SPIF_UPDATEINIFILE = 0x01 (write to user profile)
    // SPIF_SENDCHANGE = 0x02 (broadcast change)
    final imagePathPtr = imagePath.toNativeUtf16();
    try {
      final result = SystemParametersInfo(
        SPI_SETDESKWALLPAPER,
        0,
        imagePathPtr,
        SPIF_UPDATEINIFILE | SPIF_SENDCHANGE,
      );
      if (result == 0) {
        throw Exception('System call to set wallpaper failed.');
      }
    } finally {
      malloc.free(imagePathPtr);
    }
  }
}
