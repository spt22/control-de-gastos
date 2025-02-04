import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import '../services/storage_service.dart';
import '../services/pdf_generator.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _resultados = [];

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _buscar() {
    final desc = _descCtrl.text.trim();
    final lista = StorageService.getFilteredRecords(
      descripcion: desc,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() {
      _resultados = lista;
    });
  }

  Future<void> _generarPdfBusqueda() async {
    if (_resultados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay resultados para generar PDF')),
      );
      return;
    }
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
    final file = await PdfGenerator.generatePdf(
      title: 'Busqueda_$formattedDate',
      registros: _resultados,
    );
    await PdfGenerator.previewPdf(file);
  }

  Future<void> _compartirPdfBusqueda() async {
    if (_resultados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay resultados para compartir PDF')),
      );
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
    final file = await PdfGenerator.generatePdf(
      title: 'Busqueda_$formattedDate',
      registros: _resultados,
    );
    await Share.shareXFiles([XFile(file.path)], text: 'Resultados de la búsqueda');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de Transacciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selectDateRange,
              child: const Text('Seleccionar Rango de Fechas'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _buscar,
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _generarPdfBusqueda,
              child: const Text('Generar PDF de la Búsqueda'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _compartirPdfBusqueda,
              child: const Text('Compartir PDF de la Búsqueda'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _resultados.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.builder(
                      itemCount: _resultados.length,
                      itemBuilder: (context, index) {
                        final r = _resultados[index];
                        return ListTile(
                          title: Text('${r['descripcion']} (${r['tipo']})'),
                          subtitle: Text('Cantidad: ${r['cantidad']} €  |  Fecha: ${r['fecha']}'),
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
