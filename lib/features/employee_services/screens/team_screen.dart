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
import '../../../data/models/expense_models.dart';
import '../../../data/models/team_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../controllers/team_controller.dart';
import '../employee_service.dart';

const _orange = Color(0xFFEF6C00);

/// فريقي (لمعتمِدي الإجازات أو المصاريف فقط، للعرض فقط): قسمان، طلبات الإجازات
/// وطلبات المصاريف المعلقة للموظفين الذين المستخدم معتمِدهم. لا رواتب، ولا
/// أزرار موافقة أو رفض.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final TeamController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(TeamController(context.read<ErpEmployeeRepository>()));
  }

  @override
  void dispose() {
    Get.delete<TeamController>();
    super.dispose();
  }

  String _message(Object e) {
    if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
      return EssStrings.noPermission;
    }
    return describeError(e, fallback: EssStrings.teamLoadFailed);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(EmployeeService.team.title);

    return Obx(() {
      if (!_c.checked.value) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: _c.error.value != null
              ? ErrorView(message: _message(_c.error.value!), onRetry: _c.load)
              : LoadingView(message: EssStrings.loadingTeam),
        );
      }
      // بلا صلاحية: لا يُعرض أي طلب
      if (!_c.hasAccess) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: EmptyView(
            icon: Icons.lock_outline,
            title: EssStrings.teamNoAccess,
          ),
        );
      }

      final leaves = _c.leaves.toList();
      final expenses = _c.expenses.toList();
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: title,
            bottom: TabBar(
              tabs: [
                Tab(text: EssStrings.teamLeavesTab(leaves.length)),
                Tab(text: EssStrings.teamExpensesTab(expenses.length)),
              ],
            ),
          ),
          body: Column(
            children: [
              if (_c.loading.value) const LinearProgressIndicator(minHeight: 2),
              const _ViewOnlyNote(),
              Expanded(
                child: TabBarView(
                  children: [
                    _list(
                      allowed: _c.canApproveLeaves.value,
                      notAllowed: EssStrings.notLeaveApprover,
                      empty: EssStrings.noTeamLeaves,
                      emptyIcon: Icons.beach_access_outlined,
                      children: [for (final r in leaves) _LeaveCard(item: r)],
                    ),
                    _list(
                      allowed: _c.canApproveExpenses.value,
                      notAllowed: EssStrings.notExpenseApprover,
                      empty: EssStrings.noTeamExpenses,
                      emptyIcon: Icons.receipt_long_outlined,
                      children: [
                        for (final r in expenses) _ExpenseCard(item: r),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _list({
    required bool allowed,
    required String notAllowed,
    required String empty,
    required IconData emptyIcon,
    required List<Widget> children,
  }) {
    final error = _c.error.value;
    if (error != null && children.isEmpty) {
      return ErrorView(message: _message(error), onRetry: _c.load);
    }
    return RefreshIndicator(
      onRefresh: _c.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!allowed)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyView(icon: Icons.lock_outline, title: notAllowed),
            )
          else if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyView(icon: emptyIcon, title: empty),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _ViewOnlyNote extends StatelessWidget {
  const _ViewOnlyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              EssStrings.teamViewOnly,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة طلب: اسم الموظف، نوع الطلب، التاريخ، المبلغ (للمصروف)، الحالة
class _RequestCard extends StatelessWidget {
  final IconData icon;
  final String employee;
  final String type;
  final String date;
  final String? amount;

  const _RequestCard({
    required this.icon,
    required this.employee,
    required this.type,
    required this.date,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Text(
                employee.isEmpty ? '?' : employee.characters.first,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (amount != null)
                        Text(
                          amount!,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(type, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.hourglass_top,
                          size: 15,
                          color: _orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          EssStrings.statusAwaiting,
                          style: const TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final TeamLeaveRequest item;

  const _LeaveCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final r = item.request;
    return _RequestCard(
      icon: Icons.beach_access_outlined,
      employee: item.employeeName,
      type: '${EssStrings.leaveRequestType}: ${r.leaveType}',
      date:
          '${EssStrings.period(loc.formatMediumDate(r.from), loc.formatMediumDate(r.to))}'
          '  •  ${EssStrings.daysValue(r.days)}',
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final TeamExpenseRequest item;

  const _ExpenseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final c = item.claim;
    final date = c.expenseDate ?? c.postingDate;
    final kind = ExpenseKind.transport.matches(c.expenseType)
        ? EssStrings.transport
        : ExpenseKind.meals.matches(c.expenseType)
        ? EssStrings.meals
        : c.expenseType;
    return _RequestCard(
      icon: Icons.receipt_long_outlined,
      employee: item.employeeName,
      type: kind.isEmpty
          ? EssStrings.expenseRequestType
          : '${EssStrings.expenseRequestType}: $kind',
      date: [
        if (date != null) loc.formatMediumDate(date),
        c.name,
      ].join('  •  '),
      amount: formatAmount(c.amount, currency: displayCurrency(c.currency)),
    );
  }
}
