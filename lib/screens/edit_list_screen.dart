import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'edit_dialog.dart';

class EditListScreen extends StatefulWidget {
  const EditListScreen({super.key});

  @override
  State<EditListScreen> createState() => _EditListScreenState();
}

class _EditListScreenState extends State<EditListScreen> {
  List<Map<String, dynamic>> _registros = [];

  @override
  void initState() {
    super.initState();
    _cargarRegistros();
  }

  void _cargarRegistros() {
    _registros = StorageService.getAllRecords();
    setState(() {});
  }

  void _borrarRegistro(int index) async {
    await StorageService.deleteRecord(index);
    _cargarRegistros();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro eliminado')),
    );
  }

  void _editarRegistro(int index) async {
    final registro = _registros[index];
    showDialog(
      context: context,
      builder: (_) => EditDialog(
        registroOriginal: registro,
        onSave: (nuevoRegistro) async {
          await StorageService.editRecord(index, nuevoRegistro);
          _cargarRegistros();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrar / Editar Apuntes'),
      ),
      body: _registros.isEmpty
          ? const Center(child: Text('No hay registros'))
          : ListView.builder(
              itemCount: _registros.length,
              itemBuilder: (context, index) {
                final r = _registros[index];
                return ListTile(
                  title: Text('${r['descripcion']} (${r['tipo']})'),
                  subtitle: Text('Cantidad: ${r['cantidad']} € - Fecha: ${r['fecha']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editarRegistro(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _borrarRegistro(index),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
