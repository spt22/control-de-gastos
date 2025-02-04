import 'package:flutter/material.dart';
import '../services/pdf_generator.dart';
import 'package:share_plus/share_plus.dart';

class PdfButton extends StatelessWidget {
  final String mes;
  final double saldo;
  final List<Map<String, dynamic>> registros;
  final bool esBusqueda;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String criterioBusqueda;

  const PdfButton({
    super.key,
    required this.mes,
    required this.saldo,
    required this.registros,
    this.esBusqueda = false,
    this.fromDate,
    this.toDate,
    this.criterioBusqueda = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.visibility),
          label: const Text('Vista Previa'),
          onPressed: () async {
            if (registros.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No hay registros para visualizar.')),
              );
              return;
            }

            final title = esBusqueda
                ? 'Registros_${criterioBusqueda}_${fromDate?.year}-${fromDate?.month}-${fromDate?.day}_a_${toDate?.year}-${toDate?.month}-${toDate?.day}'
                : 'Registros_$mes';

            final file = await PdfGenerator.generatePdf(
              title: title,
              registros: registros,
              saldoFinal: saldo,
              esBusqueda: esBusqueda,
              fromDate: fromDate,
              toDate: toDate,
              criterioBusqueda: criterioBusqueda,
            );

            PdfGenerator.previewPdf(file);
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Generar y Compartir PDF'),
          onPressed: () async {
            if (registros.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No hay registros para generar un PDF.')),
              );
              return;
            }

            final title = esBusqueda
                ? 'Registros_${criterioBusqueda}_${fromDate?.year}-${fromDate?.month}-${fromDate?.day}_a_${toDate?.year}-${toDate?.month}-${toDate?.day}'
                : 'Registros_$mes';

            final file = await PdfGenerator.generatePdf(
              title: title,
              registros: registros,
              saldoFinal: saldo,
              esBusqueda: esBusqueda,
              fromDate: fromDate,
              toDate: toDate,
              criterioBusqueda: criterioBusqueda,
            );

            Share.shareXFiles([XFile(file.path)], text: 'Aquí tienes el PDF generado');
          },
        ),
      ],
    );
  }
}
