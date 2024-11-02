import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bling_bling/notification/local_notification.dart';
import 'package:bling_bling/src/charts_feature/charts_view.dart';
import 'package:bling_bling/src/core/cubit/water_level_cubit.dart';
import 'package:bling_bling/src/core/utils/functions.dart';
import 'package:bling_bling/src/core/utils/sp_helper.dart';
import 'package:bling_bling/src/core/utils/sp_strings.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeService();
  await LocalNotification.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SPHelper.sp.initSharedPreferences();

  // Bloc.observer = const WaterLevelObserver();

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  runApp(BlocProvider(
    lazy: false,
    create: (context) {
      final waterLevelCubit = WaterLevelCubit();
      waterLevelCubit.waterLevelSubscription();
      return waterLevelCubit;
    },
    child: MyApp(settingsController: settingsController),
  ));
}

void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

// this will be used as notification channel id
const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 888;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: true,
      autoStartOnBoot: true,

      notificationChannelId: notificationChannelId,
      // this must match with notification channel you created above.
      initialNotificationTitle: 'Bling SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: notificationId,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // DartPluginRegistrant.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await SPHelper.sp.initSharedPreferences();

  // final firestore = FirebaseFirestore.instance;

  DatabaseReference distanceRef =
      FirebaseDatabase.instance.ref('arduino/distance');

  blingNotification({required double distance, required double waterLevel}) {
    flutterLocalNotificationsPlugin.show(
      notificationId,
      'ALERT! Water level is currently at ${distance.toStringAsFixed(1)} cm (${waterLevel.toStringAsFixed(1)}%)',
      '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'Bling FOREGROUND SERVICE',
          icon: 'humidity_icon',
          // ongoing: true,
          importance: Importance.high,
          priority: Priority.high,
          // timeoutAfter: 8000,
          // enableVibration: true,
          // playSound: true,
          // silent: false,
          additionalFlags: Int32List.fromList(<int>[4]),

          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'id_2',
              'Open',
              // titleColor: Color.fromARGB(255, 255, 0, 0),
              showsUserInterface: true,
              icon: DrawableResourceAndroidBitmap('humidity_icon'),
              // contextual: true,
            ),
          ],
        ),
      ),
    );
  }

  // Stream<DocumentSnapshot<Map<String, dynamic>>> waterLevelStream =
  // firestore.collection('water_level').doc('arduino').snapshots();

  StreamSubscription<DatabaseEvent> waterLevelListen;

  waterLevelListen = distanceRef.onValue.listen((DatabaseEvent event) async {
    // print("Realtime $data");
    if (event.snapshot.exists) {
      final distance = (event.snapshot.value as num).toDouble();
      print('Water level: ${distance}');

      await SPHelper.sp.prefs?.reload();

      final selectedOperation1 =
          SPHelper.sp.getString(SPStrings.selectedLogicalOperation1) ??
              LogicOperatorLabel.lessThanOrEqual.value;
      final selectedOperation2 =
          SPHelper.sp.getString(SPStrings.selectedLogicalOperation2) ??
              LogicOperatorLabel.greaterThanOrEqual.value;
      final switchTankLevel1 =
          SPHelper.sp.getBool(SPStrings.switchTankLevel1) ?? false;
      final switchTankLevel2 =
          SPHelper.sp.getBool(SPStrings.switchTankLevel2) ?? false;
      final tankLevel1 = SPHelper.sp.getInt(SPStrings.tankLevel1) ?? 7;
      final tankLevel2 = SPHelper.sp.getInt(SPStrings.tankLevel2) ?? 95;

      final commands = [
        (selectedOperation1, switchTankLevel1, tankLevel1),
        (selectedOperation2, switchTankLevel2, tankLevel2)
      ];

      final currentTankLevel = getTankLevelPercentage(distance);

      // BUG
      // final currentTankLevelFloor = currentTankLevel.floor();

      for (final command in commands) {
        for (final operator in LogicOperatorLabel.values) {
          if (operator.value == command.$1 && command.$2) {
            switch (operator) {
              case LogicOperatorLabel.greaterThanOrEqual:
                currentTankLevel >= command.$3
                    ? blingNotification(
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
              case LogicOperatorLabel.greaterThan:
                currentTankLevel > command.$3
                    ? blingNotification(
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
              case LogicOperatorLabel.lessThanOrEqual:
                currentTankLevel <= command.$3
                    ? blingNotification(
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
              case LogicOperatorLabel.lessThan:
                currentTankLevel < command.$3
                    ? blingNotification(
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
              case LogicOperatorLabel.equal:
                currentTankLevel == command.$3
                    ? blingNotification(
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
            }
          }
        }
      }
    }
  });

  // final waterLevelListen = waterLevelStream.listen((snapshot) async {
  //
  //    if (snapshot.exists) {
  //      final data = snapshot.data()!;
  //      final distance = double.parse(data['distance'].toString());
  //      print('Water level: ${distance}');
  //
  //      await SPHelper.sp.prefs?.reload();
  //
  //      final selectedOperation1 = SPHelper.sp.getString(
  //          SPStrings.selectedLogicalOperation1) ??
  //          LogicOperatorLabel.lessThanOrEqual.value;
  //      final selectedOperation2 = SPHelper.sp.getString(
  //          SPStrings.selectedLogicalOperation2) ??
  //          LogicOperatorLabel.greaterThanOrEqual.value;
  //      final switchTankLevel1 = SPHelper.sp.getBool(
  //          SPStrings.switchTankLevel1) ?? false;
  //      final switchTankLevel2 = SPHelper.sp.getBool(
  //          SPStrings.switchTankLevel2) ?? false;
  //      final tankLevel1 = SPHelper.sp.getInt(SPStrings.tankLevel1) ?? 7;
  //      final tankLevel2 = SPHelper.sp.getInt(SPStrings.tankLevel2) ?? 95;
  //
  //
  //      final commands = [
  //        (selectedOperation1, switchTankLevel1, tankLevel1),
  //        (selectedOperation2, switchTankLevel2, tankLevel2)
  //      ];
  //
  //      final currentTankLevel = getTankLevelPercentage(distance);
  //
  //      // BUG
  //      // final currentTankLevelFloor = currentTankLevel.floor();
  //
  //      for (final command in commands) {
  //        for (final operator in LogicOperatorLabel.values) {
  //          if (operator.value == command.$1 && command.$2) {
  //            switch (operator) {
  //              case LogicOperatorLabel.greaterThanOrEqual:
  //                currentTankLevel>= command.$3
  //                    ? blingNotification(
  //                    waterLevel: currentTankLevel, distance: distance)
  //                    : null;
  //                break;
  //              case LogicOperatorLabel.greaterThan:
  //                currentTankLevel> command.$3
  //                    ? blingNotification(
  //                    waterLevel: currentTankLevel, distance: distance)
  //                    : null;
  //              case LogicOperatorLabel.lessThanOrEqual:
  //                currentTankLevel<= command.$3
  //                    ? blingNotification(
  //                    waterLevel: currentTankLevel, distance: distance)
  //                    : null;
  //                break;
  //              case LogicOperatorLabel.lessThan:
  //                currentTankLevel< command.$3
  //                    ? blingNotification(
  //                    waterLevel: currentTankLevel, distance: distance)
  //                    : null;
  //                break;
  //              case LogicOperatorLabel.equal:
  //                currentTankLevel== command.$3
  //                    ? blingNotification(
  //                    waterLevel: currentTankLevel, distance: distance)
  //                    : null;
  //                break;
  //            }
  //          }
  //        }
  //      }
  //    }
  //  });

  service.on("stop").listen((event) {
    waterLevelListen.cancel();
    service.stopSelf();
    print("background process is now stopped");
  });

  service.on("start").listen((event) {});

  Timer.periodic(const Duration(seconds: 2), (timer) {
    // blingNotification(distance: 35, waterLevel: 30);
    // print("service is successfully running ${DateTime.now().second}");
  });
}
