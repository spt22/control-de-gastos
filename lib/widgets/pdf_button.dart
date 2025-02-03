import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../screens/pdf_generator.dart';

class PdfButton extends StatelessWidget {
  final String mes;
  final double saldo;
  final List<Map<String, dynamic>> registros;

  const PdfButton({
    super.key,
    required this.mes,
    required this.saldo,
    required this.registros,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final file = await PDFGenerator.generarPDF(mes, saldo, registros);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generado en: ${file.path}')),
        );
        try {
          await OpenFile.open(file.path);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el PDF.')),
          );
        }
      },
      child: const Text('Generar PDF'),
    );
  }
}
