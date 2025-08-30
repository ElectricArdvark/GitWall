import 'package:intl/intl.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// Returns the full name of the current day of the week (e.g., "Monday").
String getCurrentDay() {
  return DateFormat('EEEE').format(DateTime.now());
}

/// Returns the primary display's resolution as a string (e.g., "1920x1080").
Future<String> getPrimaryDisplayResolution() async {
  Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
  int width = primaryDisplay.size.width.toInt();
  int height = primaryDisplay.size.height.toInt();
  return '${width}x$height';
}
