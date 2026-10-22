import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../data/models/order_models.dart';
import '../controllers/order_controller.dart';
import 'animated_amount.dart';
import 'qty_control.dart';

/// الخطوة 3: فاتورة الزبون — الأصناف المختارة بأسعارها وكمياتها والإجمالي،
/// مع اختيار تاريخ التسليم. الكمية قابلة للتعديل والصنف قابل للإزالة.
class InvoiceStep extends StatelessWidget {
  const InvoiceStep({super.key});

  String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}';
  }

  Future<void> _pickDate(BuildContext context, OrderController c) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: c.deliveryDate.isBefore(c.today) ? c.today : c.deliveryDate,
      firstDate: c.today,
      lastDate: c.today.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) c.setDeliveryDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrderController>();
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final customer = c.customer;
    final lines = c.lines;

    if (lines.isEmpty) {
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: AppStrings.invoiceLinesEmpty,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // ترويسة الفاتورة: العميل والتاريخ
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: scheme.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.invoiceHeading,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
                    foregroundColor: scheme.onPrimary,
                    child: Text(
                      (customer?.name ?? '').isEmpty
                          ? AppStrings.unknownInitial
                          : customer!.name[0],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((customer?.phone ?? '').isNotEmpty)
                          Text(
                            customer!.phone,
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${AppStrings.orderDate}: ${_date(c.today)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),

        // جسم الفاتورة: سطر لكل صنف
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                _InvoiceLine(line: lines[i], index: i + 1),
                if (i < lines.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: scheme.outlineVariant,
                  ),
              ],
              // الإجمالي
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.orderTotal,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            AppStrings.selectedItemsCount(c.lineCount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedAmount(
                      value: c.total,
                      currency: c.orderCurrency,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // تاريخ التسليم
        Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pickDate(context, c),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_rounded,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.deliveryDate,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _date(c.deliveryDate),
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_calendar_outlined, color: scheme.primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ملاحظات الطلبية (اختيارية) قبل الإرسال
        const _NotesField(),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppStrings.savedAsDraft,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// حقل ملاحظات الطلبية. النص يُحفظ في [OrderController] أثناء الكتابة، فلا يضيع
/// عند الرجوع إلى الخطوة السابقة ثم العودة.
class _NotesField extends StatefulWidget {
  const _NotesField();

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: context.read<OrderController>().notes);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.read<OrderController>();
    return TextField(
      controller: _text,
      minLines: 2,
      maxLines: 5,
      maxLength: 500,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: c.setNotes,
      decoration: InputDecoration(
        labelText: AppStrings.orderNotes,
        hintText: AppStrings.orderNotesHint,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  final CartLine line;
  final int index;

  const _InvoiceLine({required this.line, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.read<OrderController>();
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: AppStrings.removeItem,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                onPressed: () => c.remove(line.item.code),
              ),
            ],
          ),
          Text(
            '${AppStrings.unitPrice}: ${formatAmount(line.rate, currency: c.orderCurrency)}'
            '${line.item.uom.isEmpty ? '' : ' / ${line.item.uom}'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              children: [
                QtyControl(
                  dense: true,
                  qty: line.qty,
                  max: line.pricing.available,
                  onIncrement: () => c.increment(line.item),
                  onDecrement: () => c.decrement(line.item),
                  onTyped: (v) => c.setQty(line.item, v),
                ),
                const Spacer(),
                Text(
                  '${formatQty(line.qty)} × ${formatAmount(line.rate, currency: c.orderCurrency)}',
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatAmount(line.total, currency: c.orderCurrency),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
