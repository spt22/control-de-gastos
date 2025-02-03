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
  late TextEditingController descripcionController;
  late TextEditingController cantidadController;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    descripcionController =
        TextEditingController(text: widget.registroOriginal['descripcion']);
    cantidadController = TextEditingController(
      text: widget.registroOriginal['cantidad'].toString(),
    );

    // Convertir "yyyy-MM-dd" a DateTime
    final fechaStr = widget.registroOriginal['fecha'] as String;
    selectedDate = _stringToDate(fechaStr);
  }

  DateTime _stringToDate(String fechaStr) {
    // asumiendo formato "yyyy-MM-dd"
    final partes = fechaStr.split('-');
    final year = int.parse(partes[0]);
    final month = int.parse(partes[1]);
    final day = int.parse(partes[2]);
    return DateTime(year, month, day);
  }

  String _dateToString(DateTime date) {
    // Devolvemos "yyyy-MM-dd"
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (nuevaFecha != null) {
      setState(() {
        selectedDate = nuevaFecha;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaFormateada = DateFormat('yyyy-MM-dd').format(selectedDate);

    return AlertDialog(
      title: const Text('Editar registro'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad (€)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Fecha: $fechaFormateada'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Cambiar Fecha'),
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
            final cant = double.tryParse(cantidadController.text) ?? 0.0;
            if (descripcionController.text.isEmpty || cant <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos inválidos')),
              );
              return;
            }
            final nuevoRegistro = {
              ...widget.registroOriginal,
              'descripcion': descripcionController.text,
              'cantidad': cant,
              'fecha': _dateToString(selectedDate),
            };
            widget.onSave(nuevoRegistro);
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
