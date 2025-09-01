import 'package:win32_registry/win32_registry.dart';
import 'dart:io';
import '../constants.dart';

class StartupService {
  final String _runKeyPath =
      'Software\\Microsoft\\Windows\\CurrentVersion\\Run';

  void enableAutostart() {
    final key = Registry.openPath(
      RegistryHive.currentUser,
      path: _runKeyPath,
      desiredAccessRights: AccessRights.writeOnly,
    );
    // Use the absolute path to the currently running executable
    key.createValue(
      RegistryValue.string(appTitle, Platform.resolvedExecutable),
    );
    key.close();
  }

  void disableAutostart() {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: _runKeyPath,
        desiredAccessRights: AccessRights.writeOnly,
      );
      key.deleteValue(appTitle);
      key.close();
    } catch (e) {
      // This error is expected if the key doesn't exist, so we can ignore it.
      // print("Could not disable autostart (key likely doesn't exist): $e");
    }
  }
}
