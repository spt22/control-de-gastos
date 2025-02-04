import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const String _KEY = 'control_gastos';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _migrateOldDataIfNeeded();
  }

  /// Verifica si hay registros antiguos sin 'id' y les asigna uno.
  static void _migrateOldDataIfNeeded() {
    final records = getAllRecords();
    bool changed = false;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    for (var r in records) {
      if (!r.containsKey('id')) {
        // Asigna un id único si no existe
        r['id'] = nowMillis + records.indexOf(r); 
        changed = true;
      }
    }
    if (changed) {
      saveAllRecords(records);
    }
  }

  // ----------- CRUD BÁSICO -----------

  /// Retorna TODOS los registros en la app.
  static List<Map<String, dynamic>> getAllRecords() {
    final dataString = _prefs.getString(_KEY);
    if (dataString == null) return [];
    final List rawList = jsonDecode(dataString);
    return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Guarda (sobrescribe) la lista completa de registros.
  static Future<void> saveAllRecords(List<Map<String, dynamic>> records) async {
    final jsonString = jsonEncode(records);
    await _prefs.setString(_KEY, jsonString);
  }

  /// Crea un nuevo registro con ID único.
  static Future<void> addRecord(Map<String, dynamic> newRecord) async {
    final records = getAllRecords();
    newRecord['id'] = DateTime.now().millisecondsSinceEpoch;
    records.add(newRecord);
    await saveAllRecords(records);
  }

  /// Edita un registro por ID.
  static Future<void> editRecord(int id, Map<String, dynamic> updatedRecord) async {
    final records = getAllRecords();
    final index = records.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      updatedRecord['id'] = id; // Mantiene el mismo ID
      records[index] = updatedRecord;
      await saveAllRecords(records);
    }
  }

  /// Elimina un registro por ID.
  static Future<void> deleteRecord(int id) async {
    final records = getAllRecords();
    final index = records.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      records.removeAt(index);
      await saveAllRecords(records);
    }
  }

  // ----------- FILTRADO Y SALDOS -----------

  /// Filtra por descripción y rango de fechas.
  /// Ajusta fechas para cubrir el día completo (00:00 a 23:59).
  static List<Map<String, dynamic>> getFilteredRecords({
    String descripcion = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final all = getAllRecords();

    return all.where((registro) {
      final parsed = DateTime.parse(registro['fecha']);
      final fecha = DateTime(parsed.year, parsed.month, parsed.day);

      final desc = (registro['descripcion'] ?? '').toString().toLowerCase();
      final query = descripcion.toLowerCase();

      final matchDesc = query.isEmpty || desc.contains(query);

      bool matchStart = true;
      bool matchEnd = true;

      if (startDate != null) {
        final s = DateTime(startDate.year, startDate.month, startDate.day);
        matchStart = fecha.isAfter(s) || fecha.isAtSameMomentAs(s);
      }
      if (endDate != null) {
        final e = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        matchEnd = fecha.isBefore(e) || fecha.isAtSameMomentAs(e);
      }

      return matchDesc && matchStart && matchEnd;
    }).toList();
  }

  /// Calcula el saldo total (todos los registros).
  static double getSaldoActual() {
    final records = getAllRecords();
    double saldo = 0.0;
    for (var r in records) {
      final tipo = r['tipo'] ?? '';
      final cantidad = (r['cantidad'] ?? 0.0) as double;
      if (tipo == 'Ingreso') {
        saldo += cantidad;
      } else if (tipo == 'Gasto') {
        saldo -= cantidad;
      }
    }
    return saldo;
  }

  /// Retorna todos los apuntes del mes actual (orden descendente).
  static List<Map<String, dynamic>> getRecordsOfCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    final endOfMonth = firstDayNextMonth.subtract(const Duration(seconds: 1));

    final monthRecords = getFilteredRecords(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    monthRecords.sort((a, b) {
      final fechaA = DateTime.parse(a['fecha']);
      final fechaB = DateTime.parse(b['fecha']);
      return fechaB.compareTo(fechaA); // descendente
    });
    return monthRecords;
  }

  /// Calcula el saldo solo del mes actual.
  static double getSaldoOfCurrentMonth() {
    final monthRecords = getRecordsOfCurrentMonth();
    double saldo = 0.0;
    for (var r in monthRecords) {
      final tipo = r['tipo'] ?? '';
      final cant = (r['cantidad'] ?? 0.0) as double;
      if (tipo == 'Ingreso') {
        saldo += cant;
      } else if (tipo == 'Gasto') {
        saldo -= cant;
      }
    }
    return saldo;
  }
}
