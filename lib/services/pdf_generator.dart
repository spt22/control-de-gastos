import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PdfGenerator {
  /// Genera un PDF con la lista de [registros].
  /// - [title]: Nombre del archivo PDF.
  /// - [monthYear]: "Mes Año" (opcional). Si no se pasa, no se muestra en el PDF.
  /// - [saldo]: Saldo total (opcional).
  static Future<File> generatePdf({
    required String title,
    required List<Map<String, dynamic>> registros,
    String? monthYear, // 🔹 Ahora es opcional
    double? saldo,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Mostrar mes/año si está definido
              if (monthYear != null) 
                pw.Text(
                  'Listado de Apuntes del mes de $monthYear',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),

              pw.SizedBox(height: 8),

              // Fecha de generación
              pw.Text(
                'Generado: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
              ),

              // Mostrar saldo (si aplica)
              if (saldo != null) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Saldo actual: ${saldo.toStringAsFixed(2)} euros',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: saldo >= 0 ? PdfColors.green : PdfColors.red,
                  ),
                ),
              ],

              pw.SizedBox(height: 20),

              // Tabla: reemplazamos "€" con "euros"
              pw.Table.fromTextArray(
                headers: ['Fecha', 'Descripción', 'Tipo', 'Cantidad (euros)'],
                data: registros.map((r) {
                  final fecha = DateTime.parse(r['fecha']);
                  return [
                    dateFormat.format(fecha),
                    r['descripcion'],
                    r['tipo'],
                    '${r['cantidad'].toStringAsFixed(2)} euros',
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                cellStyle: pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    // Guardar en la carpeta de documentos
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/$title.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> previewPdf(File file) async {
    await OpenFile.open(file.path);
  }
}
