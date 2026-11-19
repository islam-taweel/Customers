import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/return_models.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../controllers/van_return_controller.dart';

/// إرجاع منتجات: فواتير الفان المعتمدة (Submitted)، اختيار الفاتورة، ثم
/// المنتجات وكمية الإرجاع (لا تتجاوز المسموح)، والحفظ مسودة Sales Invoice من
/// نوع Return مرتبطة بالفاتورة الأصلية، مع عرض القيم كما حسبها ERPNext.
class VanReturnScreen extends StatefulWidget {
  const VanReturnScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const VanReturnScreen());

  @override
  State<VanReturnScreen> createState() => _VanReturnScreenState();
}

class _VanReturnScreenState extends State<VanReturnScreen> {
  late final VanReturnController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(VanReturnController(context.read<ErpVanSalesRepository>()));
  }

  @override
  void dispose() {
    Get.delete<VanReturnController>();
    super.dispose();
  }

  Future<void> _open(VanInvoice invoice) async {
    _c.selectInvoice(invoice);
    final result = await Navigator.of(context).push<VanReturnResult>(
      MaterialPageRoute(builder: (_) => _ItemsScreen(controller: _c)),
    );
    if (result == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _ResultScreen(result: result)),
    );
    // الفاتورة قد تصير «Credit Note Issued» بعد اعتماد المرتجع
    if (mounted) _c.loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(VanStrings.returnTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => _c.query.value = v,
              decoration: InputDecoration(
                hintText: VanStrings.searchInvoice,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final list = _c.filteredInvoices;
              if (_c.invoicesLoading.value && _c.invoices.isEmpty) {
                return LoadingView(message: VanStrings.loadingInvoices);
              }
              final error = _c.invoicesError.value;
              if (error != null && _c.invoices.isEmpty) {
                return ErrorView(
                  message: describeError(
                    error,
                    fallback: VanStrings.invoicesFailed,
                  ),
                  onRetry: _c.loadInvoices,
                );
              }
              if (_c.invoices.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _c.loadInvoices,
                  child: ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyView(
                        icon: Icons.receipt_long_outlined,
                        title: VanStrings.noInvoices,
                        message: VanStrings.noInvoicesHint,
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _c.loadInvoices,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text(
                      VanStrings.chooseInvoice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(child: Text(VanStrings.noMatch)),
                      )
                    else
                      for (final i in list)
                        _InvoiceCard(invoice: i, onTap: () => _open(i)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final VanInvoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final i = invoice;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.receipt_long_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.customerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      [
                        i.name,
                        if (i.postingDate != null)
                          loc.formatMediumDate(i.postingDate!),
                        i.status,
                      ].join('  •  '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatAmount(
                  i.grandTotal,
                  currency: displayCurrency(i.currency),
                ),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// منتجات الفاتورة: تحديد المنتج وكمية الإرجاع، ثم الحفظ مسودة
class _ItemsScreen extends StatelessWidget {
  final VanReturnController controller;

  const _ItemsScreen({required this.controller});

  Future<void> _save(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final (result, error) = await controller.save();
    if (result != null) {
      navigator.pop(result);
    } else if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 8)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(VanStrings.returnTitle),
              Text(
                c.invoice.value?.name ?? '',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        final items = c.items.toList();
        if (c.itemsLoading.value && items.isEmpty) {
          return LoadingView(message: VanStrings.loadingItems);
        }
        final error = c.itemsError.value;
        if (error != null && items.isEmpty) {
          return ErrorView(
            message: describeError(error, fallback: VanStrings.itemsFailed),
            onRetry: c.loadItems,
          );
        }
        final invoice = c.invoice.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (invoice != null)
              Text(
                '${invoice.customerName}  •  ${VanStrings.invoiceTotal(formatAmount(invoice.grandTotal, currency: displayCurrency(invoice.currency)))}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              VanStrings.chooseItems,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              _ReturnItemCard(controller: c, item: item),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(() {
            final count = c.quantities.length;
            return FilledButton.icon(
              onPressed: c.saving.value || count == 0
                  ? null
                  : () => _save(context),
              icon: c.saving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_return_outlined),
              label: Text(
                count == 0
                    ? VanStrings.needReturnLines
                    : '${VanStrings.saveReturn} (${VanStrings.selectedForReturn(count)})',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// منتج في الفاتورة: المباع وما أُرجع والمسموح، وتحديده مع كمية الإرجاع
class _ReturnItemCard extends StatefulWidget {
  final VanReturnController controller;
  final ReturnableItem item;

  const _ReturnItemCard({required this.controller, required this.item});

  @override
  State<_ReturnItemCard> createState() => _ReturnItemCardState();
}

class _ReturnItemCardState extends State<_ReturnItemCard> {
  late final TextEditingController _qty = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = widget.controller;
    final item = widget.item;
    final none = item.returnable <= 0;

    return Obx(() {
      final selected = c.isSelected(item);
      final qty = c.quantities[item.rowName];
      final error = selected ? VanReturnController.validate(item, qty) : null;

      return Opacity(
        opacity: none ? 0.55 : 1,
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: selected
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: scheme.primary, width: 2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: none
                          ? null
                          : (v) {
                              c.toggle(item, v ?? false);
                              _qty.text = v == true
                                  ? WarehouseStrings.qty(item.returnable)
                                  : '';
                            },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${item.itemCode}  •  ${formatAmount(item.rate)} / ${item.uom}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            children: [
                              Text(
                                VanStrings.soldQty(
                                  WarehouseStrings.qty(item.qty, item.uom),
                                ),
                                style: theme.textTheme.bodySmall,
                              ),
                              if (item.returnedQty > 0)
                                Text(
                                  VanStrings.returnedQty(
                                    WarehouseStrings.qty(
                                      item.returnedQty,
                                      item.uom,
                                    ),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              Text(
                                none
                                    ? VanStrings.nothingReturnable
                                    : VanStrings.returnableQty(
                                        WarehouseStrings.qty(
                                          item.returnable,
                                          item.uom,
                                        ),
                                      ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: none ? scheme.outline : scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: TextField(
                      controller: _qty,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: !item.wholeNumber,
                      ),
                      onChanged: (v) => c.setQty(item, parseAmount(v)),
                      decoration: InputDecoration(
                        labelText: VanStrings.returnQty,
                        suffixText: item.uom,
                        isDense: true,
                        border: const OutlineInputBorder(),
                        errorText: error,
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// مستند الإرجاع بعد الحفظ: القيم والإجمالي كما حسبها ERPNext
class _ResultScreen extends StatelessWidget {
  final VanReturnResult result;

  const _ResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = result;
    final cur = displayCurrency(r.currency);
    String money(double v) => formatAmount(v, currency: cur);

    Widget row(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? const TextStyle(fontWeight: FontWeight.w800)
                  : TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              color: strong ? scheme.primary : null,
              fontSize: strong ? 17 : null,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(VanStrings.returnSavedTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    size: 40,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.name,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${VanStrings.returnAgainst}: ${r.returnAgainst}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < r.lines.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    title: Text(
                      r.lines[i].itemName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${WarehouseStrings.qty(r.lines[i].qty, r.lines[i].uom)}  ×  ${money(r.lines[i].rate)}',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                    ),
                    trailing: Text(
                      money(r.lines[i].amount),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  row(VanStrings.netTotal, money(r.netTotal)),
                  if (r.taxes != 0) row(VanStrings.taxes, money(r.taxes)),
                  const Divider(height: 16),
                  row(
                    VanStrings.returnValue,
                    money(r.grandTotal),
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            VanStrings.returnSavedNote,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(VanStrings.done),
          ),
        ),
      ),
    );
  }
}
