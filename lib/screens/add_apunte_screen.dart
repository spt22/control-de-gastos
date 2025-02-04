import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../services/pdf_generator.dart';
import 'edit_dialog.dart';

class AddApunteScreen extends StatefulWidget {
  const AddApunteScreen({super.key});

  @override
  State<AddApunteScreen> createState() => _AddApunteScreenState();
}

class _AddApunteScreenState extends State<AddApunteScreen> {
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _cantidadCtrl = TextEditingController();

  double _saldoMes = 0.0; // Saldo del mes actual
  List<Map<String, dynamic>> _registrosMes = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Carga el saldo del mes y los apuntes del mes.
  void _cargarDatos() {
    _saldoMes = StorageService.getSaldoOfCurrentMonth();
    _registrosMes = StorageService.getRecordsOfCurrentMonth();
    setState(() {});
  }

  /// Añadir gasto o ingreso
  Future<void> _addRecord(String tipo) async {
    final desc = _descripcionCtrl.text.trim();
    final cantidadText = _cantidadCtrl.text.trim();

    if (desc.isEmpty || cantidadText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete la descripción y la cantidad')),
      );
      return;
    }

    final cantidad = double.tryParse(cantidadText);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }

    final nuevoRegistro = {
      'descripcion': desc,
      'cantidad': cantidad,
      // Fecha actual en formato "yyyy-MM-dd"
      'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'tipo': tipo, // "Ingreso" o "Gasto"
      // El 'id' se genera en StorageService.addRecord()
    };

    await StorageService.addRecord(nuevoRegistro);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$tipo añadido exitosamente')),
    );

    // Limpiar campos
    _descripcionCtrl.clear();
    _cantidadCtrl.clear();

    // Recargar saldo del mes y apuntes
    _cargarDatos();
  }

  /// Generar PDF de los apuntes del mes actual, mostrando el saldo del mes.
  Future<void> _generatePdf() async {
    final registros = StorageService.getRecordsOfCurrentMonth();
    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para generar PDF este mes')),
      );
      return;
    }

    final now = DateTime.now();
    // Para el nombre del PDF
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

    // Para mostrar en el PDF: "junio 2025", por ejemplo
    final monthYear = DateFormat('MMMM yyyy', 'es').format(now);

    final file = await PdfGenerator.generatePdf(
      title: 'ApuntesMes_$formattedDate', // nombre del archivo
      monthYear: monthYear,              // se mostrará en el PDF
      registros: registros,
      saldo: _saldoMes,                  // Saldo del mes
    );

    await PdfGenerator.previewPdf(file);
  }

  /// Confirmar antes de borrar un apunte
  Future<void> _confirmarBorrar(Map<String, dynamic> registro) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que deseas eliminar este apunte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (respuesta == true) {
      await _borrarRegistro(registro);
    }
  }

  /// Borrar un registro tras confirmación
  Future<void> _borrarRegistro(Map<String, dynamic> registro) async {
    final id = registro['id'] as int; // usar el ID para eliminar
    await StorageService.deleteRecord(id);
    _cargarDatos();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro eliminado')),
    );
  }

  /// Editar un registro
  Future<void> _editarRegistro(Map<String, dynamic> registro) async {
    final id = registro['id'] as int;

    showDialog(
      context: context,
      builder: (_) => EditDialog(
        registroOriginal: registro,
        onSave: (nuevoRegistro) async {
          await StorageService.editRecord(id, nuevoRegistro);
          _cargarDatos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Formatear el mes actual (Ej: "junio 2025") en español
    final mesActual = DateFormat('MMMM yyyy', 'es').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Apunte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // (1) Mostrar el mes actual y saldo del mes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mesActual.toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Saldo: ${_saldoMes.toStringAsFixed(2)} euros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _saldoMes >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // (2) Campos para agregar un nuevo apunte
            TextField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad (euros)'),
            ),
            const SizedBox(height: 10),

            // Botones Añadir Gasto / Ingreso
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _addRecord('Gasto'),
                  child: const Text('Añadir Gasto'),
                ),
                ElevatedButton(
                  onPressed: () => _addRecord('Ingreso'),
                  child: const Text('Añadir Ingreso'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // (3) Botón para Generar PDF (del mes actual)
            ElevatedButton(
              onPressed: _generatePdf,
              child: const Text('Generar PDF'),
            ),

            const SizedBox(height: 20),

            // (4) Lista de todos los apuntes del mes actual, con Editar y Borrar
            Expanded(
              child: _registrosMes.isEmpty
                  ? const Center(child: Text('No hay apuntes este mes'))
                  : ListView.builder(
                      itemCount: _registrosMes.length,
                      itemBuilder: (context, index) {
                        final r = _registrosMes[index];
                        return Card(
                          child: ListTile(
                            title: Text('${r['descripcion']} (${r['tipo']})'),
                            subtitle: Text(
                              'Cantidad: ${r['cantidad']} euros | Fecha: ${r['fecha']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editarRegistro(r),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmarBorrar(r),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
