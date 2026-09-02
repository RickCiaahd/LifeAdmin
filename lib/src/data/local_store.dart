import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/life_object.dart';
import '../domain/responsibility.dart';

class LocalStore {
  static const _objectsKey = 'life_objects';
  static const _responsibilitiesKey = 'responsibilities';

  Future<List<LifeObject>> loadObjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_objectsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => LifeObject.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Responsibility>> loadResponsibilities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_responsibilitiesKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Responsibility.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveObjects(List<LifeObject> objects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _objectsKey,
      jsonEncode(objects.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> saveResponsibilities(
    List<Responsibility> responsibilities,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _responsibilitiesKey,
      jsonEncode(responsibilities.map((item) => item.toJson()).toList()),
    );
  }
}
