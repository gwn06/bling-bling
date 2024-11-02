// import 'package:bling_bling/notification/local_notification.dart';
import 'package:bling_bling/src/charts_feature/widgets/info_card.dart';
import 'package:bling_bling/src/charts_feature/widgets/waterlevel_card.dart';
import 'package:bling_bling/src/core/cubit/water_level_cubit.dart';
import 'package:bling_bling/src/core/utils/functions.dart';
import 'package:bling_bling/src/core/utils/sp_helper.dart';
import 'package:bling_bling/src/core/utils/sp_strings.dart';
import 'package:bling_bling/src/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

enum LogicOperatorLabel {
  greaterThanOrEqual(label: "Greater than or equal", value: ">="),
  greaterThan(label: "Greater than ", value: ">"),
  lessThanOrEqual(label: "Less than or equal", value: "<="),
  lessThan(label: "Less than ", value: "<"),
  equal(label: "Equal", value: "==");

  const LogicOperatorLabel({required this.label, required this.value});

  final String label;
  final String value;
}

class ChartsView extends StatefulWidget {
  static const routeName = '/';

  const ChartsView({super.key});

  @override
  State<ChartsView> createState() => _ChartsViewState();
}

class _ChartsViewState extends State<ChartsView> {
  var headerInfoText = SPHelper.sp.getString(SPStrings.headerInfoText) ??
      SPStrings.defaultHeaderInfoText;

  var waterDistanceEmpty =
      SPHelper.sp.getDouble(SPStrings.waterDistanceEmpty) ?? 0;
  var waterDistanceFull =
      SPHelper.sp.getDouble(SPStrings.waterDistanceFull) ?? 0;
  var selectedOperation1 =
      SPHelper.sp.getString(SPStrings.selectedLogicalOperation1) ??
          LogicOperatorLabel.lessThanOrEqual.value;
  var selectedOperation2 =
      SPHelper.sp.getString(SPStrings.selectedLogicalOperation2) ??
          LogicOperatorLabel.greaterThanOrEqual.value;
  var tankLevel1 = SPHelper.sp.getInt(SPStrings.tankLevel1) ?? 7;
  var tankLevel2 = SPHelper.sp.getInt(SPStrings.tankLevel2) ?? 95;
  var switchTankLevel1 =
      SPHelper.sp.getBool(SPStrings.switchTankLevel1) ?? false;
  var switchTankLevel2 =
      SPHelper.sp.getBool(SPStrings.switchTankLevel2) ?? false;

  var appbarTitle = SPHelper.sp.getString(SPStrings.appBarTitle) ??
      SPStrings.defaultAppBarTitle;

  late TextEditingController appbarController;

  late TextEditingController headerInfoController;

  late TextEditingController emptyTankController;

  late TextEditingController fullTankController;

  late TextEditingController tankLevel1Controller;

  late TextEditingController tankLevel2Controller;

  var isDialogOpen = false;

  @override
  void initState() {
    appbarController = TextEditingController(text: appbarTitle);
    headerInfoController = TextEditingController(text: headerInfoText);
    emptyTankController =
        TextEditingController(text: waterDistanceEmpty.toString());
    fullTankController =
        TextEditingController(text: waterDistanceFull.toString());
    tankLevel1Controller = TextEditingController(text: tankLevel1.toString());
    tankLevel2Controller = TextEditingController(text: tankLevel2.toString());
    super.initState();
  }

  @override
  void dispose() {
    appbarController.dispose();
    headerInfoController.dispose();
    emptyTankController.dispose();
    fullTankController.dispose();
    tankLevel1Controller.dispose();
    tankLevel2Controller.dispose();
    super.dispose();
  }

  void _showWaterLevelWarningDialog(BuildContext context,
      {required double distance, required double waterLevel}) {
    if (isDialogOpen) return;
    isDialogOpen = true;
    Vibration.hasVibrator().then(
      (value) {
        if (value != null && value) {
          Vibration.hasCustomVibrationsSupport().then(
            (value) {
              if (value != null && value) {
                Vibration.vibrate(duration: 8000);
              } else {
                Vibration.vibrate();
              }
            },
          );
        }
      },
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'WATER LEVEL REACHED $distance cm (${waterLevel.toStringAsFixed(1)})%',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              FilledButton(
                onPressed: () {
                  isDialogOpen = false;
                  Vibration.cancel();
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      isDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    void displayWarningLevel({required double distance}) {
      final currentTankLevel = getTankLevelPercentage(distance);

      final currentTankLevelFloor = currentTankLevel.floor();
      final commands = [
        (selectedOperation1, switchTankLevel1, tankLevel1),
        (selectedOperation2, switchTankLevel2, tankLevel2)
      ];
      for (final command in commands) {
        for (final operator in LogicOperatorLabel.values) {
          if (operator.value == command.$1 && command.$2) {
            switch (operator) {
              case LogicOperatorLabel.greaterThanOrEqual:
                currentTankLevelFloor >= command.$3
                    ? _showWaterLevelWarningDialog(context,
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
              case LogicOperatorLabel.greaterThan:
                currentTankLevelFloor > command.$3
                    ? _showWaterLevelWarningDialog(context,
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
              case LogicOperatorLabel.lessThanOrEqual:
                currentTankLevelFloor <= command.$3
                    ? _showWaterLevelWarningDialog(context,
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
              case LogicOperatorLabel.lessThan:
                currentTankLevelFloor < command.$3
                    ? _showWaterLevelWarningDialog(context,
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
              case LogicOperatorLabel.equal:
                currentTankLevelFloor == command.$3
                    ? _showWaterLevelWarningDialog(context,
                        waterLevel: currentTankLevel, distance: distance)
                    : null;
                break;
            }
          }
        }
      }
    }

    return BlocListener<WaterLevelCubit, double>(
      listener: (context, state) {
        displayWarningLevel(distance: state);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: buildAppBarWidget(context, appbarController),
          actions: [
            IconButton.filled(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              onPressed: () {
                Navigator.restorablePushNamed(context, SettingsView.routeName);
              },
            ),
            const SizedBox(width: 8)
          ],
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              buildHeaderInfoWidget(
                  context, headerInfoController, headerInfoText),
              const SizedBox(height: 10),
              buildWaterLevelWidget(
                  context,
                  emptyTankController,
                  fullTankController,
                  selectedOperation1,
                  tankLevel1Controller,
                  switchTankLevel1,
                  selectedOperation2,
                  tankLevel2Controller,
                  switchTankLevel2),
            ],
          ),
        ),
      ),
    );
  }

  InkWell buildAppBarWidget(
      BuildContext context, TextEditingController appbarController) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          showDragHandle: true,
          context: context,
          builder: (context) {
            return SizedBox(
              height: 650,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "App bar title",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        maxLength: 18,
                        controller: appbarController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Title",
                        ),
                        maxLines: 1,
                        onChanged: (value) {
                          if (value.isEmpty) return;
                          setState(() {
                            appbarController.text = value;
                            SPHelper.sp
                                .saveString(SPStrings.appBarTitle, value);
                          });
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              SPHelper.sp.saveString(SPStrings.appBarTitle,
                                  SPStrings.defaultAppBarTitle);
                            });
                          },
                          child: const Text("Reset"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Text(appbarController.text, style: const TextStyle(fontSize: 36)),
    );
  }

  InkWell buildWaterLevelWidget(
      BuildContext context,
      TextEditingController emptyTankController,
      TextEditingController fullTankController,
      String selectedOperation1,
      TextEditingController tankLevel1Controller,
      bool switchTankLevel1,
      String selectedOperation2,
      TextEditingController tankLevel2Controller,
      bool switchTankLevel2) {
    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            final operationsItems = [
              LogicOperatorLabel.equal,
              LogicOperatorLabel.greaterThan,
              LogicOperatorLabel.greaterThanOrEqual,
              LogicOperatorLabel.lessThan,
              LogicOperatorLabel.lessThanOrEqual,
            ];

            return SingleChildScrollView(
              child: StatefulBuilder(builder: (context, setSheetState) {
                return SizedBox(
                  height: 650,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        // mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Water Distance",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: emptyTankController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Empty tank",
                              suffixText: "cm",
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) return;
                              var parsedValue = double.tryParse(value) ?? 0;
                              SPHelper.sp.saveDouble(
                                  SPStrings.waterDistanceEmpty, parsedValue);
                            },
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: fullTankController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Full tank",
                              suffixText: "cm",
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) return;
                              var parsedValue = double.tryParse(value) ?? 0;
                              SPHelper.sp.saveDouble(
                                  SPStrings.waterDistanceFull, parsedValue);
                            },
                          ),
                          const SizedBox(height: 18),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Notification",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                flex: 4,
                                child: DropdownButton<String>(
                                  value: selectedOperation1,
                                  items: operationsItems
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item.value,
                                          child: Text(item.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setSheetState(() {
                                      selectedOperation1 = value!;
                                      SPHelper.sp.saveString(
                                          SPStrings.selectedLogicalOperation1,
                                          value);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 2,
                                child: TextField(
                                  controller: tankLevel1Controller,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                    // Allow only digits
                                  ],
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Tank level",
                                    suffixText: "%",
                                  ),
                                  onChanged: (value) {
                                    if (value.isEmpty) return;
                                    var parsedValue = int.tryParse(value) ?? 0;
                                    SPHelper.sp.saveInt(
                                        SPStrings.tankLevel1, parsedValue);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                  flex: 1,
                                  child: Switch(
                                    value: switchTankLevel1,
                                    onChanged: (value) {
                                      setSheetState(() {
                                        switchTankLevel1 = value;
                                        SPHelper.sp.saveBool(
                                            SPStrings.switchTankLevel1, value);
                                      });
                                    },
                                  ))
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                flex: 4,
                                child: DropdownButton<String>(
                                  value: selectedOperation2,
                                  items: operationsItems
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item.value,
                                          child: Text(item.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setSheetState(() {
                                      selectedOperation2 = value!;
                                      SPHelper.sp.saveString(
                                          SPStrings.selectedLogicalOperation2,
                                          value);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 2,
                                child: TextField(
                                  controller: tankLevel2Controller,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                    // Allow only digits
                                  ],
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Tank level",
                                    suffixText: "%",
                                  ),
                                  onChanged: (value) {
                                    if (value.isEmpty) return;
                                    var parsedValue = int.tryParse(value) ?? 0;
                                    SPHelper.sp.saveInt(
                                        SPStrings.tankLevel2, parsedValue);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                  flex: 1,
                                  child: Switch(
                                    value: switchTankLevel2,
                                    onChanged: (value) {
                                      setSheetState(() {
                                        switchTankLevel2 = value;
                                        SPHelper.sp.saveBool(
                                            SPStrings.switchTankLevel2, value);
                                      });
                                    },
                                  ))
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
      child: const WaterLevelCard(),
    );
  }

  InkWell buildHeaderInfoWidget(BuildContext context,
      TextEditingController headerInfoController, String headerInfoText) {
    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return SizedBox(
              height: 650,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Info",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        maxLength: 100,
                        controller: headerInfoController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Header",
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.isEmpty) return;
                          setState(() {
                            headerInfoController.text = value;
                            SPHelper.sp
                                .saveString(SPStrings.headerInfoText, value);
                          });
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              SPHelper.sp.saveString(SPStrings.headerInfoText,
                                  SPStrings.defaultHeaderInfoText);
                            });
                          },
                          child: const Text("Reset"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: InfoCard(header: headerInfoText),
    );
  }
}
