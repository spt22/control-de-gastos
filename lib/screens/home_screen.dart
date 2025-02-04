import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import 'add_apunte_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _saldo = 0.0;
  List<Map<String, dynamic>> _ultimosRegistros = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    // Cargar saldo total
    _saldo = StorageService.getSaldoActual();
    // Cargar 5 últimos apuntes del mes actual
    _ultimosRegistros = StorageService.getRecordsOfCurrentMonth().take(5).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Gastos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1) Fecha de hoy
            Text(
              'Hoy es $hoy',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 2) Saldo actualizado
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 30, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    'Saldo Actual: ${_saldo.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _saldo >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3) Últimos 5 apuntes del mes
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Últimos 5 apuntes de este mes',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _ultimosRegistros.isEmpty
                ? const Text('No hay apuntes este mes.')
                : Expanded(
                    child: ListView.builder(
                      itemCount: _ultimosRegistros.length,
                      itemBuilder: (context, index) {
                        final reg = _ultimosRegistros[index];
                        return Card(
                          child: ListTile(
                            title: Text('${reg['descripcion']} (${reg['tipo']})'),
                            subtitle: Text(
                              'Cantidad: ${reg['cantidad']} € | Fecha: ${reg['fecha']}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 10),

            // 4) Botones: Agregar Apunte, Buscar, Salir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddApunteScreen()),
                    );
                    _cargarDatos(); // Recargar saldo y apuntes al regresar
                  },
                  child: const Text('Agregar Apunte'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                    _cargarDatos(); // Recargar saldo y apuntes al regresar
                  },
                  child: const Text('Buscar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Salir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
