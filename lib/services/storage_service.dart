import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const String _KEY = 'control_gastos';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Obtiene TODOS los registros guardados.
  static List<Map<String, dynamic>> getAllRecords() {
    final dataString = _prefs.getString(_KEY);
    if (dataString == null) return [];
    final List rawList = jsonDecode(dataString);
    return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Sobrescribe la lista completa de registros.
  static Future<void> saveAllRecords(List<Map<String, dynamic>> records) async {
    final jsonString = jsonEncode(records);
    await _prefs.setString(_KEY, jsonString);
  }

  /// Agrega un nuevo registro con un ID único.
  static Future<void> addRecord(Map<String, dynamic> newRecord) async {
    final records = getAllRecords();
    newRecord['id'] = DateTime.now().millisecondsSinceEpoch; // ID único
    records.add(newRecord);
    await saveAllRecords(records);
  }

  /// Edita un registro identificándolo por su ID.
  static Future<void> editRecord(int id, Map<String, dynamic> updatedRecord) async {
    final records = getAllRecords();
    final index = records.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      // Mantenemos el mismo ID para no perder la referencia
      updatedRecord['id'] = id;
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

  /// Filtra registros por descripción y rango de fechas [startDate, endDate].
  /// Ajusta las fechas para ignorar la hora y filtrar correctamente.
  static List<Map<String, dynamic>> getFilteredRecords({
    String descripcion = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final all = getAllRecords();

    return all.where((registro) {
      // Parseamos la fecha almacenada (ej. "2023-06-07")
      final parsed = DateTime.parse(registro['fecha']);
      // Ajustamos a (año, mes, día) para evitar problemas de hora
      final fecha = DateTime(parsed.year, parsed.month, parsed.day);

      final desc = (registro['descripcion'] ?? '').toString().toLowerCase();
      final query = descripcion.toLowerCase();

      // Verificar si coincide la descripción (si hay búsqueda)
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

  /// Calcula el saldo total (sumando ingresos y restando gastos) de TODOS los registros.
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

  /// Obtiene TODOS los apuntes del mes actual, ordenados de más reciente a más antiguo.
  static List<Map<String, dynamic>> getRecordsOfCurrentMonth() {
    final now = DateTime.now();
    // Inicio del mes
    final startOfMonth = DateTime(now.year, now.month, 1);
    // Fin del mes (ej. para junio sería 30 de junio 23:59:59)
    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    final endOfMonth = firstDayNextMonth.subtract(const Duration(seconds: 1));

    final monthRecords = getFilteredRecords(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    // Orden descendente por fecha
    monthRecords.sort((a, b) {
      final fechaA = DateTime.parse(a['fecha']);
      final fechaB = DateTime.parse(b['fecha']);
      return fechaB.compareTo(fechaA);
    });
    return monthRecords;
  }

  /// Calcula el saldo del MES actual (ingresos - gastos solo de este mes).
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
