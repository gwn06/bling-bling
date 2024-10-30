import 'package:bling_bling/src/core/utils/sp_helper.dart';
import 'package:bling_bling/src/core/utils/sp_strings.dart';

double getTankLevelPercentage(double distance) {
  final emptyTank = SPHelper.sp.getDouble(SPStrings.waterDistanceEmpty) ??
      0.0;
  final fullTank = SPHelper.sp.getDouble(SPStrings.waterDistanceFull) ?? 0.0;
  return ((emptyTank - distance) / (emptyTank - fullTank)) * 100;
}
