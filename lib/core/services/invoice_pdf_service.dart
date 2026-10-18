import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// يحوّل الفاتورة المعروضة على الشاشة إلى ملف PDF.
///
/// نلتقط الفاتورة كصورة من الـ widget نفسه (RepaintBoundary) ثم نضعها في صفحة PDF.
/// بهذه الطريقة يطابق الملف ما تراه على الشاشة تمامًا، ويظهر الخط العربي سليمًا
/// دون الحاجة إلى تضمين ملف خط داخل التطبيق.
/// المقابل: النص داخل الـ PDF صورة، فلا يمكن تحديده أو نسخه.
class InvoicePdfService {
  InvoicePdfService._();

  /// عرض الفاتورة داخل صفحة A4 بوحدة نقطة (point)
  static const double _invoiceWidth = 420;

  static Future<Uint8List> fromBoundary(GlobalKey boundaryKey) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('الفاتورة غير ظاهرة على الشاشة');
    }

    // pixelRatio 3 لوضوح جيد عند الطباعة
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('تعذّر التقاط صورة الفاتورة');
      return _buildPdf(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  static Future<Uint8List> _buildPdf(Uint8List png) {
    final document = pw.Document();
    final image = pw.MemoryImage(png);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Align(
          alignment: pw.Alignment.topCenter,
          // scaleDown: فاتورة طويلة بأصناف كثيرة تتصغّر لتناسب الصفحة بدل أن تفشل
          child: pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.topCenter,
            child: pw.SizedBox(width: _invoiceWidth, child: pw.Image(image)),
          ),
        ),
      ),
    );

    return document.save();
  }
}
