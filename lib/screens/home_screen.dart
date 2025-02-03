import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../widgets/month_selector.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/pdf_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  // Controlador para el campo de búsqueda
  final TextEditingController searchController = TextEditingController();

  String mesSeleccionado = ''; // "YYYY-MM"
  double saldo = 0.0;
  List<Map<String, dynamic>> registros = [];

  // El término de búsqueda
  String searchTerm = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    mesSeleccionado = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    cargarDatosMes(mesSeleccionado);
  }

  Future<void> cargarDatosMes(String mes) async {
    final mesData = await StorageService.getMesData(mes);
    setState(() {
      saldo = mesData['saldo'] ?? 0.0;
      registros = mesData['registros'] ?? [];
    });
  }

  Future<void> _guardarDatosMes() async {
    await StorageService.saveMesData(mesSeleccionado, {
      'saldo': saldo,
      'registros': registros,
    });
    await recalcularTodosLosMeses();
    await cargarDatosMes(mesSeleccionado);
  }

  Future<void> recalcularTodosLosMeses() async {
    List<String> meses = StorageService.getAllMonthsKeys();
    meses.sort();

    double saldoAcumulado = 0.0;

    for (String mesKey in meses) {
      final mesData = await StorageService.getMesData(mesKey);
      final List registrosMes = mesData['registros'] ?? [];
      double ingresos = 0.0;
      double gastos = 0.0;

      for (var r in registrosMes) {
        if (r['tipo'] == 'Ingreso') {
          ingresos += (r['cantidad'] as double);
        } else {
          gastos += (r['cantidad'] as double);
        }
      }

      final saldoMes = saldoAcumulado + (ingresos - gastos);
      await StorageService.saveMesData(mesKey, {
        'saldo': saldoMes,
        'registros': registrosMes,
      });
      saldoAcumulado = saldoMes;
    }
  }

  void agregarRegistro(bool esIngreso) {
    if (descripcionController.text.isEmpty || cantidadController.text.isEmpty) {
      _mostrarMensaje('Por favor, completa todos los campos.');
      return;
    }

    final cantidad = double.tryParse(cantidadController.text) ?? 0.0;
    if (cantidad <= 0) {
      _mostrarMensaje('La cantidad debe ser mayor a 0.');
      return;
    }

    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (esIngreso) {
      saldo += cantidad;
    } else {
      saldo -= cantidad;
    }

    setState(() {
      registros.add({
        'id': DateTime.now().microsecondsSinceEpoch,
        'tipo': esIngreso ? 'Ingreso' : 'Gasto',
        'descripcion': descripcionController.text,
        'cantidad': cantidad,
        'fecha': fecha,
      });
    });

    descripcionController.clear();
    cantidadController.clear();

    _guardarDatosMes();
  }

  void eliminarRegistro(int index) {
    final item = registros[index];
    if (item['tipo'] == 'Ingreso') {
      saldo -= item['cantidad'];
    } else {
      saldo += item['cantidad'];
    }
    setState(() {
      registros.removeAt(index);
    });
    _guardarDatosMes();
  }

  void editarRegistro(int index) {
    showDialog(
      context: context,
      builder: (_) => EditDialog(
        registroOriginal: registros[index],
        onSave: (nuevoRegistro) {
          final diferencia =
              nuevoRegistro['cantidad'] - registros[index]['cantidad'];
          if (registros[index]['tipo'] == 'Ingreso') {
            saldo += diferencia;
          } else {
            saldo -= diferencia;
          }
          setState(() {
            registros[index] = nuevoRegistro;
          });
          _guardarDatosMes();
        },
      ),
    );
  }

  Future<void> onMesCambiado(String nuevoMes) async {
    await _guardarDatosMes();
    mesSeleccionado = nuevoMes;
    await cargarDatosMes(nuevoMes);
    // limpiar búsqueda al cambiar de mes (opcional)
    setState(() {
      searchController.clear();
      searchTerm = '';
    });
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Lista filtrada según searchTerm
  List<Map<String, dynamic>> get registrosFiltrados {
    if (searchTerm.isEmpty) {
      return registros;
    } else {
      final lowerSearch = searchTerm.toLowerCase();
      return registros.where((r) {
        final desc = (r['descripcion'] as String).toLowerCase();
        return desc.contains(lowerSearch);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control de Gastos - $mesSeleccionado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // SELECCION DE MES
            MonthSelector(
              mesSeleccionado: mesSeleccionado,
              onMesCambiado: onMesCambiado,
            ),
            const SizedBox(height: 10),
            Text(
              'Saldo: €${saldo.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // CAMPOS PARA AGREGAR REGISTRO
            const SizedBox(height: 10),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => agregarRegistro(true),
                  child: const Text('Agregar Ingreso'),
                ),
                ElevatedButton(
                  onPressed: () => agregarRegistro(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Agregar Gasto'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // BUSCADOR
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por descripción',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (valor) {
                setState(() {
                  searchTerm = valor;
                });
              },
            ),
            const SizedBox(height: 10),
            // BOTON PDF (para los registros filtrados)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PdfButton(
                  mes: mesSeleccionado,
                  saldo: saldo,
                  registros: registrosFiltrados, // <-- FILTRADOS
                ),
              ],
            ),
            const SizedBox(height: 10),
            // LISTA DE REGISTROS FILTRADOS
            Expanded(
              child: ListView.builder(
                itemCount: registrosFiltrados.length,
                itemBuilder: (context, index) {
                  final item = registrosFiltrados[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${item['tipo']} - ${item['descripcion']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item['tipo'] == 'Ingreso'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      subtitle: Text(
                        '${item['fecha']} - €${item['cantidad'].toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              final realIndex = registros.indexOf(item);
                              editarRegistro(realIndex);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              final realIndex = registros.indexOf(item);
                              eliminarRegistro(realIndex);
                            },
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
