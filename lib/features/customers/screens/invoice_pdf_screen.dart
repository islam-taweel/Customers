import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_strings.dart';

/// يعرض ملف الفاتورة PDF داخل التطبيق. شريط الأدوات في أسفله
/// (من حزمة printing) فيه الطباعة والمشاركة/الحفظ.
class InvoicePdfScreen extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;

  const InvoicePdfScreen({super.key, required this.bytes, required this.fileName});

  static Route<void> route({required Uint8List bytes, required String fileName}) {
    return MaterialPageRoute<void>(
      builder: (_) => InvoicePdfScreen(bytes: bytes, fileName: fileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.invoiceTitle)),
      body: PdfPreview(
        build: (_) => bytes,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
