import 'package:shared_preferences/shared_preferences.dart';

class SPHelper {
  SPHelper._();
  static SPHelper sp = SPHelper._();
  SharedPreferences? prefs;
  Future<void> initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveString(String name, String value) async {
    await prefs!.setString(name, value);
  }
  Future<void> saveBool(String name, bool value) async {
    await prefs!.setBool(name, value);
  }
  Future<void> saveInt(String name, int value) async {
    await prefs!.setInt(name, value);
  }
  Future<void> saveDouble(String name, double value) async {
    await prefs!.setDouble(name, value);
  }

  String? getString(String key) {
    return prefs!.getString(key);
  }
  bool? getBool(String key) {
    return prefs!.getBool(key);
  }
  int? getInt(String key) {
    return prefs!.getInt(key);
  }
  double? getDouble(String key) {
    return prefs!.getDouble(key);
  }

  Future<bool> delete(String key) async {
    return await prefs!.remove(key);
  }
}