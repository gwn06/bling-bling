import 'package:bling_bling/src/core/cubit/water_level_cubit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:bling_bling/src/core/utils/functions.dart';

class WaterLevelCard extends StatefulWidget {
  const WaterLevelCard({
    super.key,
  });

  @override
  State<WaterLevelCard> createState() => _WaterLevelCardState();
}

class _WaterLevelCardState extends State<WaterLevelCard> {
  // final Stream<DocumentSnapshot<WaterLevel>> _distanceStream =
  // FirebaseFirestore.instance
  //     .collection('water_level')
  //     .doc("arduino")
  //     .withConverter(
  //   fromFirestore: WaterLevel.fromFirestore,
  //   toFirestore: (value, options) => value.toFirestore(),
  // )
  //     .snapshots();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterLevelCubit, double>(builder: (context, state) {
      final tankLevel = getTankLevelPercentage(state);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedRadialGauge(
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              radius: 150,
              value: tankLevel,
              axis: GaugeAxis(
                  min: 0,
                  max: 100,
                  degrees: 260,
                  progressBar: const GaugeBasicProgressBar(
                      gradient: GaugeAxisGradient(colors: [
                    Colors.deepPurpleAccent,
                    Colors.blueAccent,
                  ])),
                  style: GaugeAxisStyle(
                    segmentSpacing: 5,
                    thickness: 25,
                    blendColors: true,
                    background: Theme.of(context).colorScheme.surface,
                  ),
                  segments: const [
                    GaugeSegment(
                      from: 0,
                      to: 30,
                      gradient: GaugeAxisGradient(
                          colors: [Colors.red, Colors.orange]),
                    ),
                    GaugeSegment(
                      from: 30,
                      to: 66.6,
                      color: Colors.yellow,
                    ),
                    GaugeSegment(
                      from: 66.6,
                      to: 100,
                      gradient: GaugeAxisGradient(
                          colors: [Colors.yellow, Colors.blue]),
                    ),
                  ]),
              builder: (context, child, value) {
                return Center(
                  child: Text(
                    "${value.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 55,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
            Text(
              "Water Level Indicator",
              style: TextStyle(
                  fontSize: 25,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "$state cm",
              style: TextStyle(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
      );
    });
  }
}
