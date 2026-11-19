import 'package:flutter/foundation.dart';

import '../../core/utils/palestine_time.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/advance_models.dart';
import '../models/expense_models.dart';
import '../../modules/hr/attendance/models/attendance_models.dart';
import '../../modules/hr/leaves/models/leave_models.dart';
import '../../modules/hr/shared/repository/hr_employee_identity.dart';
import '../models/payslip_models.dart';
import '../models/team_models.dart';

export '../../modules/hr/shared/repository/hr_employee_identity.dart'
    show EmployeeNotLinkedException;

/// (R5) ما بقي من خدمات الموظف حتى ترحيل وحداتها في R6: العمل الإضافي، السلف،
/// المصاريف، كشوف الرواتب، فريقي. الملف الشخصي والبصمة والحضور والإجازات
/// انتقلت إلى lib/modules/hr/*/repository، والهوية إلى HrEmployeeIdentity.
/// كل التواريخ والأوقات بتوقيت فلسطين. التطبيق لا يرسل docstatus ولا يعتمد
/// شيئًا أبدًا: الموافقة من الموارد البشرية في ERPNext.
class ErpEmployeeRepository {
  ErpEmployeeRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// حد آمن لطول رابط فلتر `in`
  static const _chunk = 100;

  /// أقصى عدد مستندات تُقرأ واحدًا واحدًا عند تعذّر قراءة الجدول الفرعي
  static const _maxDocReads = 30;

  // ───────────────────────── F6) عملي الإضافي ─────────────────────────

  /// مبالغ العمل الإضافي المعتمدة (Additional Salary / Overtime) في الشهر، بالشيكل.
  Future<List<OvertimePayment>> fetchOvertime(int year, int month) async {
    final employee = await _identity.employeeId();
    final rows = await _api.getAll(
      'Additional Salary',
      fields: OvertimePayment.fields,
      filters: [
        ['employee', '=', employee],
        ['salary_component', '=', 'Overtime'],
        ['docstatus', '=', 1],
        ['payroll_date', '>=', PalestineTime.date(DateTime(year, month))],
        [
          'payroll_date',
          '<=',
          PalestineTime.date(DateTime(year, month + 1, 0)),
        ],
      ],
      orderBy: 'payroll_date asc',
    );
    return [for (final r in rows) OvertimePayment.fromJson(r)];
  }

  /// نتيجة فحص Overtime Slip (تُحفظ لبقية الجلسة: لا تتغير نسخة HRMS أثناءها)
  OvertimeSlipSupport? _overtimeSlipSupport;

  /// هل نسخة HRMS تدعم Overtime Slip؟ طلب قائمة بصف واحد: 404 (أو «DocType
  /// غير موجود») = غير مدعوم، 403 = موجود بلا صلاحية قراءة.
  Future<OvertimeSlipSupport> overtimeSlipSupport() async {
    final cached = _overtimeSlipSupport;
    if (cached != null) return cached;
    OvertimeSlipSupport result;
    try {
      await _api.getList('Overtime Slip', fields: ['name'], limitPageLength: 1);
      result = OvertimeSlipSupport.available;
    } on ErpApiException catch (e) {
      final detail = (e.detail ?? '').toLowerCase();
      if (e.type == ErpErrorType.notFound ||
          detail.contains('doesnotexist') ||
          detail.contains('not found')) {
        result = OvertimeSlipSupport.missing;
      } else if (e.type == ErpErrorType.forbidden) {
        result = OvertimeSlipSupport.noAccess;
      } else {
        rethrow; // خطأ شبكة أو خادم: لا نحفظ نتيجة خاطئة
      }
    }
    debugPrint('Overtime Slip support: $result');
    return _overtimeSlipSupport = result;
  }

  /// العمل الإضافي للشهر المختار: الساعات من Overtime Slip المعتمد إن كان مدعومًا،
  /// والمبلغ بالشيكل من Additional Salary بمكوّن Overtime. لا يحسب التطبيق شيئًا:
  /// يعرض total_overtime_duration ومدة كل بند ومبالغ Additional Salary كما هي.
  Future<OvertimeMonth> fetchOvertimeMonth(int year, int month) async {
    final from = PalestineTime.date(DateTime(year, month));
    final to = PalestineTime.date(DateTime(year, month + 1, 0));
    final results = await Future.wait([
      fetchOvertime(year, month),
      overtimeSlipSupport(),
    ]);
    final payments = results[0] as List<OvertimePayment>;
    final support = results[1] as OvertimeSlipSupport;

    if (support != OvertimeSlipSupport.available) {
      return OvertimeMonth(
        source: OvertimeSource.additionalSalary,
        slipSupport: support,
        totalSeconds: null,
        days: const [],
        slips: const [],
        payments: payments,
      );
    }

    final employee = await _identity.employeeId();
    final slips = await _api.getAll(
      'Overtime Slip',
      fields: ['name', 'start_date', 'end_date', 'total_overtime_duration'],
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
        ['start_date', '>=', from],
        ['start_date', '<=', to],
      ],
      orderBy: 'start_date asc',
    );

    var total = 0.0;
    final days = <OvertimeDay>[];
    for (final slip in slips) {
      total += _num(slip['total_overtime_duration']);
      try {
        final doc = await _api.getDoc('Overtime Slip', slip['name'].toString());
        // جدول البنود: أي جدول فرعي صفوفه فيها overtime_duration
        for (final value in doc.values) {
          if (value is! List) continue;
          for (final row in value) {
            if (row is! Map || !row.containsKey('overtime_duration')) continue;
            final date = DateTime.tryParse('${row['date']}');
            if (date == null) continue;
            days.add(
              OvertimeDay(
                date: DateTime(date.year, date.month, date.day),
                durationSeconds: _num(row['overtime_duration']),
                overtimeType: row['overtime_type']?.toString() ?? '',
              ),
            );
          }
        }
      } catch (e) {
        // البنود معلومة إضافية: الإجمالي من الكشف نفسه يكفي
        debugPrint('ErpEmployeeRepository overtime slip details failed: $e');
      }
    }
    days.sort((a, b) => a.date.compareTo(b.date));

    return OvertimeMonth(
      source: OvertimeSource.overtimeSlip,
      slipSupport: support,
      totalSeconds: total,
      days: days,
      slips: [for (final s in slips) s['name'].toString()],
      payments: payments,
    );
  }

  static double _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  // ───────────────────────── سلفي ─────────────────────────

  /// سلف الموظف الحالي فقط، الأحدث أولًا.
  Future<List<EmployeeAdvance>> fetchAdvances() async {
    final employee = await _identity.employeeId();
    final rows = await _api.getAll(
      'Employee Advance',
      fields: EmployeeAdvance.fields,
      filters: [
        ['employee', '=', employee],
      ],
      orderBy: 'creation desc',
    );
    return [for (final r in rows) EmployeeAdvance.fromJson(r)];
  }

  /// يقدّم طلب سلفة مسودة (قيد المراجعة) بالشيكل على حساب سلف الموظفين.
  /// لا docstatus: الموافقة والدفع من الموارد البشرية في ERPNext.
  Future<String> submitAdvance({
    required double amount,
    required String purpose,
  }) async {
    final emp = await _identity.employeeRow(['name', 'company']);
    final company = HrEmployeeIdentity.companyOf(emp);
    final created = await _api.postDoc('Employee Advance', {
      'employee': emp['name'],
      'company': company,
      'posting_date': PalestineTime.date(PalestineTime.today()),
      'advance_amount': amount,
      'purpose': purpose.trim(),
      'currency': ErpConfig.companyCurrency,
      'exchange_rate': 1,
      'advance_account': ErpConfig.employeeAdvanceAccount,
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Employee Advance $name created');
    return name;
  }

  // ───────────────────────── مصاريفي ─────────────────────────

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

    final details = await _expenseDetails([
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

  // ───────────────────────── كشوف رواتبي ─────────────────────────

  /// كشوف رواتب الموظف الحالي المعتمدة فقط (docstatus 1، لا مسودات)، الأحدث أولًا.
  Future<List<PayslipSummary>> fetchPayslips() async {
    final employee = await _identity.employeeId();
    final rows = await _api.getAll(
      'Salary Slip',
      fields: PayslipSummary.fields,
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
      ],
      orderBy: 'start_date desc',
    );
    return [for (final r in rows) PayslipSummary.fromJson(r)];
  }

  /// كشف راتب كاملًا. يُرفض إن لم يكن للموظف الحالي أو لم يكن معتمدًا
  /// (الصلاحية على الخادم هي الأساس، وهذا تحقق إضافي).
  Future<PayslipDetail> fetchPayslip(String name) async {
    final employee = await _identity.employeeId();
    final doc = await _api.getDoc('Salary Slip', name);
    if (doc['employee']?.toString() != employee ||
        '${doc['docstatus']}' != '1') {
      throw const ErpApiException(ErpErrorType.forbidden);
    }
    return PayslipDetail.fromJson(doc);
  }

  /// أول بند (النوع والتاريخ والوصف) لكل طلب مصروف في [names]: من الجدول
  /// الفرعي مباشرة، وإلا بقراءة المستندات نفسها (حتى _maxDocReads).
  Future<Map<String, Map<String, dynamic>>> _expenseDetails(
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

  // ───────────────────────── فريقي (للعرض فقط) ─────────────────────────

  /// هل المستخدم الحالي Leave Approver أو Expense Approver (من أدواره في ERPNext).
  Future<({bool leaves, bool expenses})> fetchApproverAccess() async {
    final roles = {
      if ((await _identity.userInfo())['roles'] case final List list)
        for (final r in list) r.toString(),
    };
    return (
      leaves: roles.contains('Leave Approver'),
      expenses: roles.contains('Expense Approver'),
    );
  }

  /// طلبات الإجازة المعلقة (Open، مسودة) التي المستخدم الحالي هو معتمِدها فقط
  /// (leave_approver)، فلا تظهر طلبات موظفين ليس مسؤولًا عنهم.
  Future<List<TeamLeaveRequest>> fetchTeamLeaves() async {
    final user = await _identity.loggedUser();
    if (user.isEmpty) return const [];
    final rows = await _api.getAll(
      'Leave Application',
      fields: [...LeaveRequest.fields, 'employee', 'employee_name'],
      filters: [
        ['leave_approver', '=', user],
        ['status', '=', 'Open'],
        ['docstatus', '=', 0],
      ],
      orderBy: 'from_date asc',
    );
    return [for (final r in rows) TeamLeaveRequest.fromJson(r)];
  }

  /// طلبات المصاريف المعلقة (مسودة لم يُوافق عليها) التي المستخدم الحالي هو
  /// معتمِدها فقط (expense_approver).
  Future<List<TeamExpenseRequest>> fetchTeamExpenses() async {
    final user = await _identity.loggedUser();
    if (user.isEmpty) return const [];
    final rows = await _api.getAll(
      'Expense Claim',
      fields: [...ExpenseClaimSummary.fields, 'employee', 'employee_name'],
      filters: [
        ['expense_approver', '=', user],
        ['docstatus', '=', 0],
        ['approval_status', '=', 'Draft'],
      ],
      orderBy: 'posting_date asc',
    );
    if (rows.isEmpty) return const [];
    final details = await _expenseDetails([
      for (final r in rows) r['name'].toString(),
    ]);
    return [
      for (final r in rows)
        TeamExpenseRequest.fromJson(r, detail: details[r['name'].toString()]),
    ];
  }
}
