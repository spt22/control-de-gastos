import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Retorna info del mes en un Map { saldo, registros[] }
  static Future<Map<String, dynamic>> getMesData(String mes) async {
    final dataString = _prefs.getString(mes);
    if (dataString == null) {
      return {
        'saldo': 0.0,
        'registros': <Map<String, dynamic>>[],
      };
    }
    final dataMap = jsonDecode(dataString);
    return {
      'saldo': dataMap['saldo'],
      'registros': List<Map<String, dynamic>>.from(dataMap['registros'] ?? []),
    };
  }

  static Future<void> saveMesData(String mes, Map<String, dynamic> mesData) async {
    final jsonString = jsonEncode({
      'saldo': mesData['saldo'],
      'registros': mesData['registros'],
    });
    await _prefs.setString(mes, jsonString);
  }

  // Devuelve todas las keys (YYYY-MM) que existan en SharedPreferences
  static List<String> getAllMonthsKeys() {
    final allKeys = _prefs.getKeys();
    final regex = RegExp(r'^\d{4}-\d{2}$'); // YYYY-MM
    return allKeys.where((k) => regex.hasMatch(k)).toList();
  }
}
