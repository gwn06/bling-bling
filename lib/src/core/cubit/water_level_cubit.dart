import 'dart:async';

import 'package:bling_bling/src/core/cubit/water_level.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WaterLevelCubit extends Cubit<double> {
  WaterLevelCubit() : super(0.0) {
    // waterLevelSubscription();
  }

  StreamSubscription<DocumentSnapshot<WaterLevel>>? _subscription;

  Future<void> waterLevelSubscription() async {
    _subscription = FirebaseFirestore.instance
        .collection('water_level')
        .doc("arduino")
        .withConverter(
          fromFirestore: WaterLevel.fromFirestore,
          toFirestore: (value, options) => value.toFirestore(),
        )
        .snapshots()
        .listen((onData) {
      if (onData.exists) {
        emit(onData.data()!.distance);
      }
    });
  }

  @override
  void onChange(Change<double> change) {
    // TODO: implement onChange
    print("${change.currentState}");
    super.onChange(change);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
