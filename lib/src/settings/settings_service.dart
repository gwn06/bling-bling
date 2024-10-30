import 'package:bling_bling/src/core/utils/sp_helper.dart';
import 'package:bling_bling/src/core/utils/sp_strings.dart';
import 'package:flutter/material.dart';

/// A service that stores and retrieves user settings.
///
/// By default, this class does not persist user settings. If you'd like to
/// persist the user settings locally, use the shared_preferences package. If
/// you'd like to store settings on a web server, use the http package.
class SettingsService {
  /// Loads the User's preferred ThemeMode from local or remote storage.
  Future<ThemeMode> themeMode() async  {
    final themeStr = SPHelper.sp.getString(SPStrings.selectedTheme) ;
    if (themeStr == "light") {
      return ThemeMode.light;
    } else if (themeStr == "dark") {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    switch (theme) {
      case ThemeMode.system:
        SPHelper.sp.saveString(SPStrings.selectedTheme, "system");
        break;
      case ThemeMode.light:
        SPHelper.sp.saveString(SPStrings.selectedTheme, "light");
      case ThemeMode.dark:
        SPHelper.sp.saveString(SPStrings.selectedTheme, "dark");
        break;
    }
  }
}
