import '../../../data/models/sales_invoice.dart';

/// فواتير المبيعات لكل العملاء، مع وقت حفظ النسخة المحلية إن كانت منها.
class SalesInvoicesResult {
  final List<SalesInvoice> invoices;

  /// null = جاءت للتو من ERPNext، وإلا وقت حفظ النسخة المحلية
  final DateTime? savedAt;

  const SalesInvoicesResult({required this.invoices, this.savedAt});
}
