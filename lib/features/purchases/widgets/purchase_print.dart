import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_strings.dart';
import '../controllers/purchases_controller.dart';

/// يجلب PDF المستند من ERPNext ويفتح نافذة الطباعة. يعرض رسالة إن تعذّر.
/// يعيد true إن فُتحت الطباعة.
Future<bool> printPurchaseDoc(
  BuildContext context,
  PurchasesController controller, {
  required String doctype,
  required String name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final pdf = await controller.downloadPdf(doctype, name);
    await Printing.layoutPdf(
      onLayout: (_) async => pdf,
      name: '${name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf',
    );
    return true;
  } catch (e) {
    debugPrint('purchase print failed ($doctype $name): $e');
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.invoicePdfFailed)),
    );
    return false;
  }
}

/// زر طباعة مع مؤشر انتظار أثناء جلب الملف.
class PrintButton extends StatefulWidget {
  final PurchasesController controller;
  final String doctype;
  final String name;

  const PrintButton({
    super.key,
    required this.controller,
    required this.doctype,
    required this.name,
  });

  @override
  State<PrintButton> createState() => _PrintButtonState();
}

class _PrintButtonState extends State<PrintButton> {
  bool _busy = false;

  Future<void> _print() async {
    if (_busy) return;
    setState(() => _busy = true);
    await printPurchaseDoc(
      context,
      widget.controller,
      doctype: widget.doctype,
      name: widget.name,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _print,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.print_outlined),
      label: Text(AppStrings.printInvoice),
    );
  }
}

/// سطر «عنوان ← قيمة» مشترك بين بطاقات المشتريات.
class InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isLtr;
  final bool emphasize;

  const InfoLine({
    super.key,
    required this.label,
    required this.value,
    this.isLtr = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                textDirection: isLtr ? TextDirection.ltr : null,
                style: TextStyle(
                  fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                  fontSize: emphasize ? 16 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
