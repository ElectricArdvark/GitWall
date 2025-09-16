import 'package:intl/intl.dart';
import 'package:win32/win32.dart';

const String defaultRepoUrl = 'https://github.com/ElectricArdvark/GitWall-WP';
const String appTitle = 'GitWall';

const List<String> supportedImageExtensions = [
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
];

/// Returns the full name of the current day of the week (e.g., "Monday").
String getCurrentDay() {
  return DateFormat('EEEE').format(DateTime.now());
}

/// Returns the primary display's resolution as a string (e.g., "1920x1080").
String getPrimaryDisplayResolution() {
  int width = GetSystemMetrics(SM_CXSCREEN);
  int height = GetSystemMetrics(SM_CYSCREEN);
  return '${width}x$height';
}

/// List of available resolutions in the app, ordered from highest to lowest
const List<String> availableResolutions = [
  '3840x2160',
  '2560x1440',
  '1920x1080',
  '1680x1050',
  '1600x900',
  '1536x864',
  '1440x900',
  '1366x768',
  '1280x1024',
  '1280x720',
  '800x600',
  '720x648',
];

/// Parses a resolution string (e.g., "1920x1080") into width and height integers
({int width, int height}) parseResolution(String resolution) {
  final parts = resolution.split('x');
  if (parts.length != 2) {
    throw FormatException('Invalid resolution format: $resolution');
  }
  return (width: int.parse(parts[0]), height: int.parse(parts[1]));
}

/// Calculates the total number of pixels for a resolution
int getResolutionPixels(String resolution) {
  final (:width, :height) = parseResolution(resolution);
  return width * height;
}

/// Automatically selects the best resolution based on screen size
/// Returns the resolution that best matches the screen size, or the next highest if exact match not found
String selectBestResolutionForScreen() {
  final screenResolution = getPrimaryDisplayResolution();
  final screenPixels = getResolutionPixels(screenResolution);

  // Find exact match first
  if (availableResolutions.contains(screenResolution)) {
    return screenResolution;
  }

  // Find the resolution with the closest pixel count (preferring higher resolution)
  String bestMatch = availableResolutions.first;
  int bestPixelDiff = (getResolutionPixels(bestMatch) - screenPixels).abs();

  for (final resolution in availableResolutions) {
    final pixelDiff = (getResolutionPixels(resolution) - screenPixels).abs();
    if (pixelDiff < bestPixelDiff) {
      bestPixelDiff = pixelDiff;
      bestMatch = resolution;
    } else if (pixelDiff == bestPixelDiff) {
      // If pixel counts are equal, prefer the higher resolution
      if (getResolutionPixels(resolution) > getResolutionPixels(bestMatch)) {
        bestMatch = resolution;
      }
    }
  }

  return bestMatch;
}
