import 'dart:async';

// import 'package:bling_bling/src/core/cubit/water_level.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WaterLevelCubit extends Cubit<double> {
  WaterLevelCubit() : super(0.0) {
    // waterLevelSubscription();
  }

  // StreamSubscription<DocumentSnapshot<WaterLevel>>? _subscription;
  StreamSubscription<DatabaseEvent>? _subscription;

  Future<void> waterLevelSubscription() async {
    DatabaseReference distanceRef =
    FirebaseDatabase.instance.ref('arduino/distance');

    distanceRef.onValue.listen((DatabaseEvent event) {
      // print("Realtime $data");
      if(event.snapshot.exists) {
        final data = (event.snapshot.value as num).toDouble();
        emit(data);
      }

    });

    // _subscription = FirebaseFirestore.instance
    //     .collection('water_level')
    //     .doc("arduino")
    //     .withConverter(
    //       fromFirestore: WaterLevel.fromFirestore,
    //       toFirestore: (value, options) => value.toFirestore(),
    //     )
    //     .snapshots()
    //     .listen((onData) {
    //   if (onData.exists) {
    //     emit(onData.data()!.distance);
    //   }
    // });
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
