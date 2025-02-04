import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../services/pdf_generator.dart';
import 'edit_list_screen.dart';

class AddApunteScreen extends StatefulWidget {
  const AddApunteScreen({super.key});

  @override
  State<AddApunteScreen> createState() => _AddApunteScreenState();
}

class _AddApunteScreenState extends State<AddApunteScreen> {
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _cantidadCtrl = TextEditingController();

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
      'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'tipo': tipo,
    };

    await StorageService.addRecord(nuevoRegistro);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$tipo añadido exitosamente')),
    );

    _descripcionCtrl.clear();
    _cantidadCtrl.clear();
  }

  Future<void> _generatePdf() async {
    final registros = StorageService.getAllRecords();
    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para generar PDF')),
      );
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
    final file = await PdfGenerator.generatePdf(
      title: 'Apuntes_$formattedDate',
      registros: registros,
    );

    await PdfGenerator.previewPdf(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Apunte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad (€)'),
            ),
            const SizedBox(height: 20),
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditListScreen()),
                );
              },
              child: const Text('Borrar / Editar Apuntes'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _generatePdf,
              child: const Text('Generar PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
