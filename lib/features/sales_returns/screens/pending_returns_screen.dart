import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/returns_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/return_models.dart';
import '../controllers/sales_returns_controller.dart';

/// المرتجعات المحفوظة مسودة: إشعارات الدائن وإرجاع البضاعة، مع اعتماد أو رفض كل منها.
/// بعد اعتماد إشعار دائن يُعرض رد المال، إلا إن كان العميل ما زال مدينًا.
class PendingReturnsScreen extends StatelessWidget {
  const PendingReturnsScreen({super.key});

  static Route<void> route(BuildContext context) {
    final factory = context.read<SalesReturnsControllerFactory>();
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<PendingReturnsController>(
        create: (_) => factory.createPending(),
        child: const PendingReturnsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PendingReturnsController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ReturnsStrings.pendingTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: '${ReturnsStrings.creditNotes} (${c.creditNotes.length})'),
              Tab(text: '${ReturnsStrings.stockReturns} (${c.stockReturns.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(context, c, c.creditNotes),
            _list(context, c, c.stockReturns),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    PendingReturnsController c,
    List<PendingReturn> items,
  ) {
    if (c.loading && items.isEmpty) return const LoadingView();
    if (c.error != null && items.isEmpty) {
      return ErrorView(message: c.error!, onRetry: c.load);
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            EmptyView(
              icon: Icons.task_alt_outlined,
              title: ReturnsStrings.noPending,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: c.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        itemBuilder: (_, i) => _PendingCard(item: items[i]),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingReturn item;

  const _PendingCard({required this.item});

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String? body,
    String action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _approve(BuildContext context) async {
    final c = context.read<PendingReturnsController>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirm(
      context,
      ReturnsStrings.approveTitle(item.name),
      null,
      ReturnsStrings.approve,
    )) {
      return;
    }
    final error = await c.approve(item);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? ReturnsStrings.approved(item.name))),
    );
    if (error != null || !item.isCreditNote || !context.mounted) return;

    // 5) رد المال بعد اعتماد إشعار الدائن
    try {
      final check = await c.checkRefund(item);
      if (!context.mounted) return;
      final currency = displayCurrency(check.currency);
      if (check.customerOutstanding > 0.005) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ReturnsStrings.customerStillOwes(
              formatAmount(check.customerOutstanding, currency: currency),
            )),
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }
      if (check.canRefund) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => _RefundSheet(
            controller: c,
            creditNote: item,
            check: check,
            messenger: messenger,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(describeError(e, fallback: ReturnsStrings.refundFailed)),
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final c = context.read<PendingReturnsController>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirm(
      context,
      ReturnsStrings.rejectTitle(item.name),
      ReturnsStrings.rejectBody,
      ReturnsStrings.reject,
    )) {
      return;
    }
    final error = await c.reject(item);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? ReturnsStrings.rejected(item.name))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PendingReturnsController>();
    final theme = Theme.of(context);
    final busy = c.isBusy(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  formatAmount(
                    item.grandTotal,
                    currency: displayCurrency(item.currency),
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(item.customerName.isEmpty ? item.customer : item.customerName),
            if (item.returnAgainst.isNotEmpty)
              Text(
                ReturnsStrings.against(item.returnAgainst),
                style: theme.textTheme.bodySmall,
              ),
            if (item.remarks.isNotEmpty)
              Text(item.remarks, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  TextButton.icon(
                    onPressed: () => _reject(context),
                    icon: Icon(Icons.close, color: theme.colorScheme.error),
                    label: Text(
                      ReturnsStrings.reject,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check),
                    label: Text(ReturnsStrings.approve),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// رد المال: طريقة الدفع (ومرجعها وتاريخه لغير النقد) ← دفعة صرف مسودة.
class _RefundSheet extends StatefulWidget {
  final PendingReturnsController controller;
  final PendingReturn creditNote;
  final RefundCheck check;
  final ScaffoldMessengerState messenger;

  const _RefundSheet({
    required this.controller,
    required this.creditNote,
    required this.check,
    required this.messenger,
  });

  @override
  State<_RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<_RefundSheet> {
  final _refNo = TextEditingController();
  DateTime? _refDate;
  List<String> _modes = const [];
  String? _mode;
  bool _modesLoading = true;
  bool _saving = false;
  String? _error;

  bool get _isCash {
    final m = (_mode ?? '').toLowerCase();
    return m.contains('cash') || m.contains('نقد');
  }

  @override
  void initState() {
    super.initState();
    _loadModes();
  }

  @override
  void dispose() {
    _refNo.dispose();
    super.dispose();
  }

  Future<void> _loadModes() async {
    try {
      final modes = await widget.controller.fetchModesOfPayment();
      if (!mounted) return;
      setState(() {
        _modes = modes;
        _mode = modes.isEmpty ? null : modes.first;
        _modesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modesLoading = false;
        _error = ReturnsStrings.modesFailed;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _refDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _refDate = picked);
  }

  Future<void> _save() async {
    final mode = _mode;
    if (mode == null) return;
    if (!_isCash && (_refNo.text.trim().isEmpty || _refDate == null)) {
      setState(() => _error = ReturnsStrings.referenceRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.controller.saveRefund(
      creditNote: widget.creditNote,
      modeOfPayment: mode,
      referenceNo: _isCash ? null : _refNo.text,
      referenceDate: _isCash ? null : _refDate,
    );
    if (!mounted) return;
    if (result.entry != null) {
      widget.messenger.showSnackBar(
        SnackBar(content: Text(ReturnsStrings.refundSaved(result.entry!))),
      );
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = formatAmount(
      widget.check.refundable,
      currency: displayCurrency(widget.check.currency),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ReturnsStrings.refundTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text('${widget.creditNote.name}  •  ${ReturnsStrings.refundAmount(amount)}'),
          const SizedBox(height: 16),
          if (_modesLoading)
            const Center(child: CircularProgressIndicator())
          else if (_modes.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _mode,
              decoration: InputDecoration(
                labelText: ReturnsStrings.paymentMode,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final m in _modes)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => setState(() => _mode = v),
            ),
          if (!_isCash && _mode != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _refNo,
              decoration: InputDecoration(
                labelText: ReturnsStrings.referenceNo,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _refDate == null
                    ? ReturnsStrings.referenceDate
                    : '${ReturnsStrings.referenceDate}: '
                        '${_refDate!.year}/${_refDate!.month}/${_refDate!.day}',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(ReturnsStrings.skipRefund),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saving || _mode == null ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(ReturnsStrings.saveRefund),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
