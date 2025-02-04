import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../services/pdf_generator.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _descripcionCtrl = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];

  Future<void> _buscar() async {
    final descripcion = _descripcionCtrl.text.trim();
    _resultados = StorageService.getFilteredRecords(descripcion: descripcion);
    setState(() {});
  }

  Future<void> _generatePdf() async {
    if (_resultados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para generar PDF')),
      );
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

    // Obtener el mes/año del primer resultado o usar el mes actual si no hay fechas
    String monthYear;
    if (_resultados.isNotEmpty) {
      final firstRecordDate = DateTime.parse(_resultados.first['fecha']);
      monthYear = DateFormat('MMMM yyyy', 'es').format(firstRecordDate);
    } else {
      monthYear = DateFormat('MMMM yyyy', 'es').format(now);
    }

    final file = await PdfGenerator.generatePdf(
      title: 'Busqueda_$formattedDate',
      registros: _resultados,
      monthYear: monthYear, // 🔹 Se pasa correctamente
    );

    await PdfGenerator.previewPdf(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Apuntes'),
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
            ElevatedButton(
              onPressed: _buscar,
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 20),
            _resultados.isEmpty
                ? const Text('No hay resultados')
                : Expanded(
                    child: ListView.builder(
                      itemCount: _resultados.length,
                      itemBuilder: (context, index) {
                        final r = _resultados[index];
                        return ListTile(
                          title: Text('${r['descripcion']} (${r['tipo']})'),
                          subtitle: Text(
                            'Cantidad: ${r['cantidad']} euros | Fecha: ${r['fecha']}',
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
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
