import 'package:flutter/material.dart';

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
  late String _fecha;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.registroOriginal['descripcion']);
    _cantCtrl = TextEditingController(text: widget.registroOriginal['cantidad'].toString());
    _tipo = widget.registroOriginal['tipo'];
    _fecha = widget.registroOriginal['fecha']; // "yyyy-MM-dd"
  }

  @override
  Widget build(BuildContext context) {
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
              'fecha': _fecha,
              'tipo': _tipo,
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
