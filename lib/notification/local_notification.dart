import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification {
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static var _id = 0;

  static Future<void> init() async {
    // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    //     FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const initializationSettingsAndroid =
        AndroidInitializationSettings('humidity_icon');
    final initializationSettingsDarwin = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) => {},
    );
    final initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) {});

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestFullScreenIntentPermission();
  }

  static Future<void> showNotification(
      {required String title,
      required String body,
      required String payload}) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 5000, 2000]);
    const int insistentFlag = 4;

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      vibrationPattern: vibrationPattern,
      // ticker: 'ticker',
      enableLights: true,
      fullScreenIntent: true,
      // autoCancel: false,
      // ongoing: true,
      timeoutAfter: 20000,
      additionalFlags: Int32List.fromList(<int>[insistentFlag]) ,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'id_2',
          'Open',
          // titleColor: Color.fromARGB(255, 255, 0, 0),
          showsUserInterface: true,
          icon: DrawableResourceAndroidBitmap('humidity_icon'),
          // contextual: true,
        ),
        // const AndroidNotificationAction(
        //   'id_3',
        //   'Stop',
        //   // showsUserInterface: true,
        //   icon: DrawableResourceAndroidBitmap('empty'),
        //   contextual: true,
        //   cancelNotification: true
        // ),
      ],
    );
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await _flutterLocalNotificationsPlugin
        .show(_id, title, body, notificationDetails, payload: payload);
  }

  static Future<bool> isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final granted = await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
      return granted;
    }
    return false;
  }

  static Future<bool?> requestNotificationsPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      return grantedNotificationPermission;
    }
  }

  static Future<bool?> requestFullScreenIntentPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedFullScreenPermission =
          await androidImplementation?.requestFullScreenIntentPermission();
      return grantedFullScreenPermission;
    }
  }

  static Future<bool?> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedExactAlarmPermission =
          await androidImplementation?.requestExactAlarmsPermission();
      return grantedExactAlarmPermission;
    }
  }
}
