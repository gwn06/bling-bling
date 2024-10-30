import 'package:bling_bling/src/charts_feature/charts_view.dart';
import 'package:flutter/material.dart';

import 'core/theme/theme.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {

        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // onGenerateTitle: (BuildContext context) =>
          //     AppLocalizations.of(context)!.appTitle,

          theme: ThemeData(
            useMaterial3: true,
            colorScheme: MaterialTheme.lightHighContrastScheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: MaterialTheme.darkHighContrastScheme(),
          ),
          themeMode: settingsController.themeMode,
          debugShowCheckedModeBanner: false,

          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case ChartsView.routeName:
                  default:
                    return const ChartsView();
                }
              },
            );
          },
        );
      },
    );
  }
}
