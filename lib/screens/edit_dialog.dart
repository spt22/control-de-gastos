import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditDialog extends StatefulWidget {
  final Map<String, dynamic> registroOriginal;
  final Function(Map<String, dynamic>) onSave;

  const EditDialog({
    super.key,
    required this.registroOriginal,
    required this.onSave,
  });

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController _descCtrl;
  late TextEditingController _cantCtrl;
  late String _tipo;
  late DateTime _fechaSeleccionada; // Se guardará como DateTime

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.registroOriginal['descripcion']);
    _cantCtrl = TextEditingController(text: widget.registroOriginal['cantidad'].toString());
    _tipo = widget.registroOriginal['tipo'];

    // Convertir 'yyyy-MM-dd' a DateTime
    final fechaStr = widget.registroOriginal['fecha'] as String;
    final partes = fechaStr.split('-');
    final year = int.parse(partes[0]);
    final month = int.parse(partes[1]);
    final day = int.parse(partes[2]);
    _fechaSeleccionada = DateTime(year, month, day);
  }

  Future<void> _pickDate() async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (nuevaFecha != null) {
      setState(() {
        _fechaSeleccionada = nuevaFecha;
      });
    }
  }

  String _dateToString(DateTime date) {
    // Convertir DateTime a 'yyyy-MM-dd'
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final fechaFormato = DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);

    return AlertDialog(
      title: const Text('Editar registro'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: _cantCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad (€)'),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _tipo,
              items: const [
                DropdownMenuItem(value: 'Gasto', child: Text('Gasto')),
                DropdownMenuItem(value: 'Ingreso', child: Text('Ingreso')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _tipo = val;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Fecha: $fechaFormato'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final desc = _descCtrl.text.trim();
            final cant = double.tryParse(_cantCtrl.text.trim()) ?? 0.0;
            if (desc.isEmpty || cant <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos inválidos')),
              );
              return;
            }
            final updated = {
              'descripcion': desc,
              'cantidad': cant,
              'fecha': _dateToString(_fechaSeleccionada), // Nuevo valor
              'tipo': _tipo,
              // 'id' se conserva en StorageService.editRecord
            };
            widget.onSave(updated);
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
