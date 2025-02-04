import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const String _KEY = 'control_gastos';

  // Inicializar
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Retorna todos los registros
  static List<Map<String, dynamic>> getAllRecords() {
    final dataString = _prefs.getString(_KEY);
    if (dataString == null) return [];
    final List rawList = jsonDecode(dataString);
    return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Guarda una lista completa de registros
  static Future<void> saveAllRecords(List<Map<String, dynamic>> records) async {
    final jsonString = jsonEncode(records);
    await _prefs.setString(_KEY, jsonString);
  }

  // Agregar un registro
  static Future<void> addRecord(Map<String, dynamic> newRecord) async {
    final records = getAllRecords();
    records.add(newRecord);
    await saveAllRecords(records);
  }

  // Editar un registro por índice
  static Future<void> editRecord(int index, Map<String, dynamic> updatedRecord) async {
    final records = getAllRecords();
    if (index >= 0 && index < records.length) {
      records[index] = updatedRecord;
      await saveAllRecords(records);
    }
  }

  // Eliminar un registro por índice
  static Future<void> deleteRecord(int index) async {
    final records = getAllRecords();
    if (index >= 0 && index < records.length) {
      records.removeAt(index);
      await saveAllRecords(records);
    }
  }

  // Filtra por descripción y rango de fechas
  static List<Map<String, dynamic>> getFilteredRecords({
    String descripcion = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final all = getAllRecords();
    return all.where((registro) {
      final fecha = DateTime.parse(registro['fecha']);
      final desc = registro['descripcion']?.toString().toLowerCase() ?? '';
      final query = descripcion.toLowerCase();

      final matchDesc = query.isEmpty || desc.contains(query);

      bool matchStart = true;
      bool matchEnd = true;

      if (startDate != null) {
        matchStart = !fecha.isBefore(startDate);
      }
      if (endDate != null) {
        matchEnd = !fecha.isAfter(endDate);
      }

      return matchDesc && matchStart && matchEnd;
    }).toList();
  }

  // ✅ NUEVO: Obtener saldo actual (Ingreso - Gasto) de todos los tiempos
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

  // ✅ NUEVO: Obtener los 5 últimos registros del mes actual, ordenados por fecha descendente
  static List<Map<String, dynamic>> getLast5RecordsOfCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    // Día 0 del siguiente mes es el último día del mes actual
    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    final endOfMonth = firstDayNextMonth.subtract(const Duration(days: 1));

    // Filtrar los registros del mes corriente
    final monthRecords = getFilteredRecords(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    // Ordenar de más reciente a más antiguo
    monthRecords.sort((a, b) {
      final fechaA = DateTime.parse(a['fecha']);
      final fechaB = DateTime.parse(b['fecha']);
      return fechaB.compareTo(fechaA); // descendente
    });

    // Tomar los 5 primeros (los más nuevos)
    return monthRecords.take(5).toList();
  }
}
