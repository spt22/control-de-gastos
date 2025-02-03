import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatelessWidget {
  final String mesSeleccionado;        // "YYYY-MM"
  final Function(String) onMesCambiado;

  const MonthSelector({
    super.key,
    required this.mesSeleccionado,
    required this.onMesCambiado,
  });

  @override
  Widget build(BuildContext context) {
    // Convertir mesSeleccionado a DateTime (día 1)
    final partes = mesSeleccionado.split('-');
    final year = int.parse(partes[0]);
    final month = int.parse(partes[1]);
    final date = DateTime(year, month, 1);

    // Ej: "1 de febrero de 2025"
    final formatted = DateFormat("d 'de' MMMM 'de' y").format(date);

    return InkWell(
      onTap: () async {
        // Mostrar DatePicker
        final nuevaFecha = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          // Opcional: locale: const Locale('es'), // si quieres forzar es
        );
        if (nuevaFecha != null) {
          // Tomamos año y mes
          final y = nuevaFecha.year;
          final m = nuevaFecha.month.toString().padLeft(2, '0');
          final nuevoMes = '$y-$m';
          onMesCambiado(nuevoMes);
        }
      },
      child: Text(
        formatted,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline, // para indicar que es clicable
        ),
      ),
    );
  }
}
