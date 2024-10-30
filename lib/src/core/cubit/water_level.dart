import 'package:cloud_firestore/cloud_firestore.dart';

class WaterLevel {
  final double distance;

  WaterLevel({required this.distance});

  factory WaterLevel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final map = snapshot.data();
    return WaterLevel(distance:  (map?['distance'] as num).toDouble() );
  }


  Map<String, dynamic> toFirestore() {
    final result = <String, dynamic>{};
    result.addAll({"distance": distance});
    return result;
  }
}
