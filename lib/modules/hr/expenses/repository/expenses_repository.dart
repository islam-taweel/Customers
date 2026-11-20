 import 'package:flutter/foundation.dart';

import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../shared/repository/hr_employee_identity.dart';
import '../models/expense_models.dart';

/// «مصاريفي»: أنواع المصاريف، الطلبات، السلف المفتوحة، وطلب مصروف مسودة مع
/// رفع صورة الإيصال. (R6) الدوال منقولة حرفيًا من ErpEmployeeRepository؛
/// expenseDetails (كانت _expenseDetails) عامة لأن «فريقي» يستخدمها أيضًا.
class ExpensesRepository {
  ExpensesRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// حد آمن لطول رابط فلتر `in`
  static const _chunk = 100;

  /// أقصى عدد مستندات تُقرأ واحدًا واحدًا عند تعذّر قراءة الجدول الفرعي
  static const _maxDocReads = 30;

  /// أسماء أنواع المصاريف المعرّفة في ERPNext (Expense Claim Type).
  Future<List<String>> fetchExpenseTypes() async {
    final rows = await _api.getAll('Expense Claim Type', fields: ['name']);
    return [for (final r in rows) r['name'].toString()];
  }

  /// طلبات مصاريف الموظف الحالي فقط، الأحدث أولًا، مع نوع وتاريخ أول بند.
  Future<List<ExpenseClaimSummary>> fetchExpenseClaims() async {
    final employee = await _identity.employeeId();
    final rows = await _api.getAll(
      'Expense Claim',
      fields: ExpenseClaimSummary.fields,
      filters: [
        ['employee', '=', employee],
      ],
      orderBy: 'creation desc',
    );
    if (rows.isEmpty) return const [];

    final details = await expenseDetails([
      for (final r in rows) r['name'].toString(),
    ]);

    return [
      for (final r in rows)
        ExpenseClaimSummary.fromJson(r, detail: details[r['name'].toString()]),
    ];
  }

  /// السلف المفتوحة للموظف كما يعيدها ERPNext لطلب المصروف
  /// (hrms...expense_claim.get_advances)، وفيها مبلغ غير مستخدم.
  Future<List<OpenAdvance>> fetchOpenAdvances() async {
    final emp = await _identity.employeeRow(['name', 'company']);
    final res = await _api.getMethod(
      'hrms.hr.doctype.expense_claim.expense_claim.get_advances',
      {
        'employee': emp['name'].toString(),
        'company': HrEmployeeIdentity.companyOf(emp),
      },
    );
    final msg = res['message'];
    return [
      if (msg is List)
        for (final r in msg)
          if (r is Map)
            if (OpenAdvance.fromJson(Map<String, dynamic>.from(r))
                    .unclaimedAmount >
                0.005)
              OpenAdvance.fromJson(Map<String, dynamic>.from(r)),
    ];
  }

  /// يحفظ طلب مصروف مسودة (بند واحد)، مربوطًا بسلفة إن اختيرت، ثم يرفع صورة
  /// الإيصال مرفقًا له. لا docstatus: الموافقة والدفع من الموارد البشرية.
  /// يعيد رقم الطلب، و attachmentError إن حُفظ الطلب وفشل رفع الإيصال.
  Future<({String name, Object? attachmentError})> submitExpense({
    required String expenseType,
    required double amount,
    required DateTime date,
    required String description,
    OpenAdvance? advance,
    Uint8List? receipt,
    String receiptName = 'receipt.jpg',
  }) async {
    final emp = await _identity.employeeRow([
      'name',
      'company',
      'expense_approver',
    ]);
    final company = HrEmployeeIdentity.companyOf(emp);
    final defaults = await _companyDefaults(company, [
      'default_expense_claim_payable_account',
    ]);
    final payable = defaults['default_expense_claim_payable_account'] ?? '';
    final approver = emp['expense_approver']?.toString() ?? '';

    final created = await _api.postDoc('Expense Claim', {
      'employee': emp['name'],
      'company': company,
      'posting_date': PalestineTime.date(PalestineTime.today()),
      if (payable.isNotEmpty) 'payable_account': payable,
      if (approver.isNotEmpty) 'expense_approver': approver,
      'expenses': [
        {
          'expense_date': PalestineTime.date(date),
          'expense_type': expenseType,
          'description': description.trim(),
          'amount': amount,
          'sanctioned_amount': amount,
        },
      ],
      if (advance != null)
        'advances': [
          {
            'employee_advance': advance.name,
            if (advance.postingDate != null)
              'posting_date': PalestineTime.date(advance.postingDate!),
            'advance_paid': advance.paidAmount,
            'unclaimed_amount': advance.unclaimedAmount,
            // لا يُخصم من السلفة أكثر من غير المستخدم فيها ولا أكثر من المصروف
            'allocated_amount': amount < advance.unclaimedAmount
                ? amount
                : advance.unclaimedAmount,
            if (advance.advanceAccount.isNotEmpty)
              'advance_account': advance.advanceAccount,
          },
        ],
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Expense Claim $name created');

    Object? attachmentError;
    if (receipt != null) {
      try {
        await _api.uploadFile(
          bytes: receipt,
          filename: receiptName,
          doctype: 'Expense Claim',
          docname: name,
        );
      } catch (e) {
        debugPrint('ErpEmployeeRepository receipt upload failed: $e');
        attachmentError = e;
      }
    }
    return (name: name, attachmentError: attachmentError);
  }

  /// حقول افتراضية من الشركة (حسابات السلف والمصاريف والعملة). فارغة إن لم
  /// يملك الموظف صلاحية قراءة الشركة، فيكملها الخادم أو يرفض برسالة واضحة.
  Future<Map<String, String>> _companyDefaults(
    String company,
    List<String> fields,
  ) async {
    try {
      final rows = await _api.getList(
        'Company',
        fields: fields,
        filters: [
          ['name', '=', company],
        ],
        limitPageLength: 1,
      );
      if (rows.isEmpty) return const {};
      return {for (final f in fields) f: rows.first[f]?.toString() ?? ''};
    } catch (e) {
      debugPrint('ErpEmployeeRepository company defaults failed: $e');
      return const {};
    }
  }

  /// أول بند (النوع والتاريخ والوصف) لكل طلب مصروف في [names]: من الجدول
  /// الفرعي مباشرة، وإلا بقراءة المستندات نفسها (حتى _maxDocReads).
  Future<Map<String, Map<String, dynamic>>> expenseDetails(
    List<String> names,
  ) async {
    // البنود من الجدول الفرعي مباشرة (parent للتحقق من الصلاحية)
    final details = <String, Map<String, dynamic>>{};
    try {
      for (var i = 0; i < names.length; i += _chunk) {
        final part = names.sublist(
          i,
          i + _chunk > names.length ? names.length : i + _chunk,
        );
        for (final d in await _api.getAll(
          'Expense Claim Detail',
          fields: [
            'parent',
            'expense_type',
            'expense_date',
            'description',
            'idx',
          ],
          filters: [
            ['parent', 'in', part],
          ],
          orderBy: 'idx asc',
          parent: 'Expense Claim',
        )) {
          details.putIfAbsent(d['parent'].toString(), () => d);
        }
      }
    } catch (e) {
      // بعض الإصدارات لا تسمح بقراءة الجدول الفرعي: نقرأ المستندات نفسها
      debugPrint('ErpEmployeeRepository expense details failed: $e');
      for (final name in names.take(_maxDocReads)) {
        try {
          final doc = await _api.getDoc('Expense Claim', name);
          final items = doc['expenses'];
          if (items is List && items.isNotEmpty && items.first is Map) {
            details[name] = Map<String, dynamic>.from(items.first as Map);
          }
        } catch (err) {
          debugPrint('ErpEmployeeRepository expense $name failed: $err');
        }
      }
    }

    return details;
  }
}
