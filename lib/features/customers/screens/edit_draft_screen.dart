import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/draft_invoice_controller.dart';

/// تعديل مسودة: كمية كل صنف (أو إزالته) وتاريخ التسليم، ثم حفظ.
/// تُرجع true عند نجاح الحفظ.
class EditDraftScreen extends StatelessWidget {
  const EditDraftScreen({super.key});

  /// تشارك متحكم المسودة نفسه، فتتحدث شاشة العرض بعد الحفظ تلقائيًا.
  static Route<bool> route(DraftInvoiceController controller) {
    return MaterialPageRoute<bool>(
      builder: (_) => ChangeNotifierProvider<DraftInvoiceController>.value(
        value: controller,
        child: const EditDraftScreen(),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DraftInvoiceController controller,
  ) async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final current = controller.deliveryDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) controller.setDeliveryDate(picked);
  }

  Future<void> _typeQty(
    BuildContext context,
    DraftInvoiceController controller,
    int index,
  ) async {
    final line = controller.lines[index];
    final text = TextEditingController(text: _plain(line.qty));
    final qty = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(line.name),
        content: TextField(
          controller: text,
          autofocus: true,
          textDirection: TextDirection.ltr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(labelText: AppStrings.quantity),
          onSubmitted: (v) => Navigator.pop(ctx, double.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(text.text)),
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
    text.dispose();
    if (qty != null && qty > 0) controller.setQty(index, qty);
  }

  Future<void> _save(
    BuildContext context,
    DraftInvoiceController controller,
  ) async {
    final navigator = Navigator.of(context);
    if (await controller.save()) navigator.pop(true);
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DraftInvoiceController>();
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final lines = controller.lines;
    final cur = displayCurrency(controller.invoice.currency);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.editDraftTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < lines.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lines[i].name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatAmount(lines[i].rate, currency: cur)} × ${_plain(lines[i].qty)} = ${formatAmount(lines[i].total, currency: cur)}',
                                  textDirection: TextDirection.ltr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => controller.decrement(i),
                          ),
                          InkWell(
                            onTap: () => _typeQty(context, controller, i),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                _plain(lines[i].qty),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => controller.increment(i),
                          ),
                          IconButton(
                            tooltip: AppStrings.removeItem,
                            icon: Icon(
                              Icons.delete_outline,
                              color: scheme.error,
                            ),
                            onPressed: () => controller.removeAt(i),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppStrings.draftNoItems,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                const SizedBox(height: 4),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  leading: const Icon(Icons.event_outlined),
                  title: Text(AppStrings.deliveryDate),
                  trailing: Text(
                    '${controller.deliveryDate.year}-'
                    '${controller.deliveryDate.month.toString().padLeft(2, '0')}-'
                    '${controller.deliveryDate.day.toString().padLeft(2, '0')}',
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleSmall,
                  ),
                  onTap: () => _pickDate(context, controller),
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.error!,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.orderTotal,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        formatAmount(controller.total, currency: cur),
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed:
                        controller.canSave ? () => _save(context, controller) : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: controller.busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(AppStrings.save),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
