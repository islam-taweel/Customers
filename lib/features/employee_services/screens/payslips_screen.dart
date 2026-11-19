import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/payslip_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../controllers/payslips_controller.dart';
import '../../../modules/hr/home/employee_service.dart';
import 'payslip_detail_screen.dart';

/// كشوف رواتبي: كشوف الموظف المسجّل دخوله المعتمدة فقط (لا مسودات)، تُحدَّث
/// من ERPNext عند الفتح. الضغط على كشف يفتح تفاصيله. للعرض فقط.
class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  late final PayslipsController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(PayslipsController(context.read<ErpEmployeeRepository>()));
  }

  @override
  void dispose() {
    Get.delete<PayslipsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(EmployeeService.payslips.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(
            () => _c.loading.value && _c.payslips.isNotEmpty
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
        ),
      ),
      body: Obx(() {
        final list = _c.payslips.toList();
        if (_c.loading.value && list.isEmpty) {
          return LoadingView(message: EssStrings.loadingPayslips);
        }
        final error = _c.error.value;
        if (error != null && list.isEmpty) {
          return ErrorView(
            message: payslipErrorMessage(error, EssStrings.payslipsLoadFailed),
            onRetry: _c.load,
          );
        }
        return RefreshIndicator(
          onRefresh: _c.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        EssStrings.readOnlyNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyView(
                    icon: Icons.request_quote_outlined,
                    title: EssStrings.noPayslips,
                    message: EssStrings.noPayslipsHint,
                  ),
                )
              else
                for (final p in list) _PayslipCard(payslip: p),
            ],
          ),
        );
      }),
    );
  }
}

/// رسالة الخطأ: غير مرتبط بموظف، بلا صلاحية، أو الخطأ العام
String payslipErrorMessage(Object e, String fallback) {
  if (e is EmployeeNotLinkedException) return EssStrings.notLinked;
  if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
    return EssStrings.noPermission;
  }
  return describeError(e, fallback: fallback);
}

/// كشف في القائمة: شهر الكشف وفترته، صافي الراتب، والإجمالي والخصومات
class _PayslipCard extends StatelessWidget {
  final PayslipSummary payslip;

  const _PayslipCard({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final p = payslip;
    final currency = displayCurrency(p.currency);
    final month = p.startDate ?? p.postingDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PayslipDetailScreen(name: p.name),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.request_quote_outlined,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month == null ? p.name : loc.formatMonthYear(month),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (p.startDate != null && p.endDate != null)
                      Text(
                        EssStrings.period(
                          loc.formatMediumDate(p.startDate!),
                          loc.formatMediumDate(p.endDate!),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${EssStrings.grossPay}: ${formatAmount(p.grossPay, currency: currency)}'
                      '  •  ${EssStrings.deductions}: ${formatAmount(p.totalDeduction, currency: currency)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatAmount(p.netPay, currency: currency),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    EssStrings.netPay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
