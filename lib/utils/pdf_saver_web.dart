import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

/// Implementación Web para guardar/descargar PDF.
Future<void> savePdfFile(Uint8List pdfBytes, String suggestedFileName) async {
  final base64Pdf = base64Encode(pdfBytes);
  final anchor =
      html.AnchorElement(href: 'data:application/pdf;base64,$base64Pdf')
        ..setAttribute("download", suggestedFileName)
        ..click();
  html.document.body?.children.remove(anchor);
}
