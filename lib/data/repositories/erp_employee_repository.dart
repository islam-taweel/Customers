import 'package:flutter/foundation.dart';

import '../../core/utils/palestine_time.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/advance_models.dart';
import '../models/attendance_models.dart';
import '../models/employee_models.dart';
import '../models/expense_models.dart';
import '../models/leave_models.dart';
import '../models/payslip_models.dart';
import '../models/team_models.dart';

/// المستخدم الحالي غير مرتبط بسجل موظف نشط في ERPNext (Employee.user_id).
class EmployeeNotLinkedException implements Exception {
  const EmployeeNotLinkedException();
}

/// خدمات الموظف من ERPNext (HRMS) للموظف المرتبط بالمستخدم الحالي: بياناته
/// وورديته، البصمات، الحضور، طلبات الحضور، الإجازات، والعمل الإضافي.
/// كل التواريخ والأوقات بتوقيت فلسطين. التطبيق لا يرسل docstatus ولا يعتمد
/// شيئًا أبدًا: الموافقة من الموارد البشرية في ERPNext.
class ErpEmployeeRepository {
  ErpEmployeeRepository(this._api);

  final ErpApiClient _api;

  /// حد آمن لطول رابط فلتر `in`
  static const _chunk = 100;

  /// أقصى عدد مستندات تُقرأ واحدًا واحدًا عند تعذّر قراءة الجدول الفرعي
  static const _maxDocReads = 30;

  static const _leaveModule =
      'hrms.hr.doctype.leave_application.leave_application';

  // ───────────────────────── F1) أنا وورديتي ─────────────────────────

  /// الموظف المرتبط بالمستخدم الحالي (hrms.api.get_current_employee_info).
  /// ردّ فارغ = المستخدم غير مرتبط بموظف.
  Future<Map<String, dynamic>> _currentEmployee() async {
    final msg = (await _api.getMethod(
      'hrms.api.get_current_employee_info',
    ))['message'];
    if (msg is! Map || '${msg['name'] ?? ''}'.isEmpty) {
      throw const EmployeeNotLinkedException();
    }
    return Map<String, dynamic>.from(msg);
  }

  /// الموظف الحالي مع [fields]: ما لا يرد في get_current_employee_info (مثل
  /// default_shift أو expense_approver) يُقرأ من Employee بنفس الرقم.
  Future<Map<String, dynamic>> _employeeRow(List<String> fields) async {
    final me = await _currentEmployee();
    final missing = [
      for (final f in fields)
        if (!me.containsKey(f)) f,
    ];
    if (missing.isEmpty) return me;
    final rows = await _api.getList(
      'Employee',
      fields: ['name', ...missing],
      filters: [
        ['name', '=', me['name']],
      ],
      limitPageLength: 1,
    );
    return rows.isEmpty ? me : {...me, ...rows.first};
  }

  /// رقم الموظف (Employee.name) المستخدم في كل الطلبات
  Future<String> _employeeId() async =>
      (await _currentEmployee())['name'].toString();

  /// الموظف مع ورديته اليوم.
  Future<EmployeeProfile> fetchProfile() async {
    final profile = EmployeeProfile.fromJson(
      await _employeeRow(EmployeeProfile.fields),
    );
    EmployeeShift? shift;
    try {
      shift = await _shift(profile.id, profile.defaultShift);
    } catch (e) {
      // الوردية معلومة إضافية: فشلها لا يمنع عرض بقية البيانات
      debugPrint('ErpEmployeeRepository shift failed: $e');
    }
    return profile.withShift(shift);
  }

  /// وردية اليوم: تعيين الوردية الساري (بلا نهاية أو نهايته اليوم أو بعده)،
  /// وإلا الوردية الافتراضية للموظف. null إن لم توجد وردية.
  Future<EmployeeShift?> _shift(String employee, String defaultShift) async {
    final today = PalestineTime.date(PalestineTime.today());
    final rows = await _api.getList(
      'Shift Assignment',
      fields: ['shift_type', 'start_date', 'end_date'],
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
        ['status', '=', 'Active'],
        ['start_date', '<=', today],
      ],
      orFilters: [
        ['end_date', '>=', today],
        ['end_date', 'is', 'not set'],
      ],
      orderBy: 'start_date desc',
      limitPageLength: 1,
    );
    final name = rows.isNotEmpty
        ? rows.first['shift_type']?.toString() ?? ''
        : defaultShift;
    if (name.isEmpty) return null;
    return EmployeeShift.fromJson(await _api.getDoc('Shift Type', name));
  }

  /// صورة الموظف (قد تكون ملفًا خاصًا فتحتاج كوكي الجلسة).
  Future<Uint8List> fetchImage(String path) => _api.downloadFile(path);

  // ───────────────────────── F2) البصمة ─────────────────────────

  /// بصمات اليوم بالترتيب (الأقدم أولًا).
  Future<List<EmployeeCheckin>> fetchTodayPunches() async {
    final employee = await _employeeId();
    final today = PalestineTime.today();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final rows = await _api.getAll(
      'Employee Checkin',
      fields: EmployeeCheckin.fields,
      filters: [
        ['employee', '=', employee],
        ['time', '>=', '${PalestineTime.date(today)} 00:00:00'],
        ['time', '<', '${PalestineTime.date(tomorrow)} 00:00:00'],
      ],
      orderBy: 'time asc',
    );
    return [for (final r in rows) EmployeeCheckin.fromJson(r)];
  }

  /// يسجّل بصمة الآن بتوقيت فلسطين. لا موقع: التطبيق لا يطلب إذن الموقع.
  Future<EmployeeCheckin> punch({required bool isIn}) async {
    final employee = await _employeeId();
    final now = PalestineTime.now();
    final created = await _api.postDoc('Employee Checkin', {
      'employee': employee,
      'log_type': isIn ? 'IN' : 'OUT',
      'time': PalestineTime.format(now),
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Employee Checkin $name (${isIn ? 'IN' : 'OUT'})');
    return EmployeeCheckin(name: name, isIn: isIn, time: now);
  }

  // ───────────────────────── F3) حضوري ─────────────────────────

  /// سجلات الحضور المعتمدة لشهر [month] من [year]، بالترتيب. مدة التأخير والخروج
  /// المبكر تُحسب من وقتي وردية الموظف الحالية.
  Future<List<AttendanceRecord>> fetchAttendance(int year, int month) async {
    final emp = await _employeeRow(['name', 'default_shift']);
    final employee = emp['name'].toString();
    final rows = await _api.getAll(
      'Attendance',
      fields: AttendanceRecord.fields,
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
        ['attendance_date', '>=', PalestineTime.date(DateTime(year, month))],
        [
          'attendance_date',
          '<=',
          PalestineTime.date(DateTime(year, month + 1, 0)),
        ],
      ],
      orderBy: 'attendance_date asc',
    );

    EmployeeShift? shift;
    if (rows.isNotEmpty) {
      try {
        shift = await _shift(employee, emp['default_shift']?.toString() ?? '');
      } catch (e) {
        // بلا أوقات الوردية: تظهر علامة التأخير دون مدته
        debugPrint('ErpEmployeeRepository attendance shift failed: $e');
      }
    }
    return [
      for (final r in rows)
        AttendanceRecord.fromJson(
          r,
          shiftStart: shift?.startTime,
          shiftEnd: shift?.endTime,
        ),
    ];
  }

  // ───────────────────────── F4) نسيت البصمة ─────────────────────────

  /// يحفظ طلب حضور ليوم [date] (مسودة = قيد المراجعة).
  /// [reason]: On Duty أو Work From Home فقط.
  Future<String> submitAttendanceRequest({
    required DateTime date,
    required String reason,
    required String explanation,
  }) async {
    final emp = await _employeeRow(['name', 'company']);
    final day = PalestineTime.date(date);
    final created = await _api.postDoc('Attendance Request', {
      'employee': emp['name'],
      'company': _companyOf(emp),
      'from_date': day,
      'to_date': day,
      'reason': reason,
      'explanation': explanation.trim(),
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Attendance Request $name created');
    return name;
  }

  /// طلباتي، الأحدث أولًا.
  Future<List<AttendanceRequestRecord>> fetchAttendanceRequests() async {
    final employee = await _employeeId();
    final rows = await _api.getAll(
      'Attendance Request',
      fields: AttendanceRequestRecord.fields,
      filters: [
        ['employee', '=', employee],
      ],
      orderBy: 'creation desc',
    );
    return [for (final r in rows) AttendanceRequestRecord.fromJson(r)];
  }

  // ───────────────────────── F5) إجازاتي ─────────────────────────

  /// أرصدة اليوم (get_leave_details)، والأنواع بدون راتب من Leave Type.is_lwp
  /// ومن message.lwps معًا.
  Future<LeaveDetails> fetchLeaveDetails() async {
    final employee = await _employeeId();
    final results = await Future.wait([
      _api.getMethod('$_leaveModule.get_leave_details', {
        'employee': employee,
        'date': PalestineTime.date(PalestineTime.today()),
      }),
      _api.getAll('Leave Type', fields: ['name', 'is_lwp']),
    ]);
    final msg = (results[0] as Map<String, dynamic>)['message'];
    final details = msg is Map
        ? LeaveDetails.fromJson(Map<String, dynamic>.from(msg))
        : const LeaveDetails(balances: [], withoutPayTypes: []);
    final lwpTypes = [
      for (final t in results[1] as List<Map<String, dynamic>>)
        if ('${t['is_lwp']}' == '1') t['name'].toString(),
    ];
    return LeaveDetails(
      balances: details.balances,
      withoutPayTypes: {...details.withoutPayTypes, ...lwpTypes}.toList(),
    );
  }

  /// طلبات الإجازة، الأحدث أولًا.
  Future<List<LeaveRequest>> fetchLeaveRequests() async {
    final employee = await _employeeId();
    final rows = await _api.getAll(
      'Leave Application',
      fields: LeaveRequest.fields,
      filters: [
        ['employee', '=', employee],
      ],
      orderBy: 'creation desc',
    );
    return [for (final r in rows) LeaveRequest.fromJson(r)];
  }

  /// أيام الإجازة كما يحسبها ERPNext (العطل لا تُحسب).
  Future<double> leaveDays({
    required String leaveType,
    required DateTime from,
    required DateTime to,
  }) async {
    final employee = await _employeeId();
    final res = await _api.getMethod('$_leaveModule.get_number_of_leave_days', {
      'employee': employee,
      'leave_type': leaveType,
      'from_date': PalestineTime.date(from),
      'to_date': PalestineTime.date(to),
    });
    final v = res['message'];
    return v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  }

  /// يقدّم طلب إجازة بحالة Open (قيد المراجعة). إن لم يكفِ الرصيد يرفضه الخادم
  /// ويصل نص الخطأ في [ErpApiException.detail].
  Future<String> submitLeave({
    required String leaveType,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) async {
    final emp = await _employeeRow(['name', 'company']);
    var approver = '';
    try {
      final res = await _api.getMethod('$_leaveModule.get_leave_approver', {
        'employee': emp['name'].toString(),
      });
      approver = res['message']?.toString() ?? '';
    } catch (e) {
      // بلا معتمِد محدد: يكمله الخادم من إعدادات الموظف أو يرفض برسالة واضحة
      debugPrint('ErpEmployeeRepository leave approver failed: $e');
    }
    final created = await _api.postDoc('Leave Application', {
      'employee': emp['name'],
      'company': _companyOf(emp),
      if (approver.isNotEmpty) 'leave_approver': approver,
      'leave_type': leaveType,
      'from_date': PalestineTime.date(from),
      'to_date': PalestineTime.date(to),
      'posting_date': PalestineTime.date(PalestineTime.today()),
      'description': reason.trim(),
      'status': 'Open',
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Leave Application $name created');
    return name;
  }

  // ───────────────────────── F6) عملي الإضافي ─────────────────────────

  /// مبالغ العمل الإضافي المعتمدة (Additional Salary / Overtime) في الشهر، بالشيكل.
  Future<List<OvertimePayment>> fetchOvertime(int year, int month) async {
    final employee = await _employeeId();
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

    final employee = await _employeeId();
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
    final employee = await _employeeId();
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
    final emp = await _employeeRow(['name', 'company']);
    final company = _companyOf(emp);
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
    final employee = await _employeeId();
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
    final emp = await _employeeRow(['name', 'company']);
    final res = await _api.getMethod(
      'hrms.hr.doctype.expense_claim.expense_claim.get_advances',
      {'employee': emp['name'].toString(), 'company': _companyOf(emp)},
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
    final emp = await _employeeRow(['name', 'company', 'expense_approver']);
    final company = _companyOf(emp);
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
    final employee = await _employeeId();
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
    final employee = await _employeeId();
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
      if ((await _userInfo())['roles'] case final List list)
        for (final r in list) r.toString(),
    };
    return (
      leaves: roles.contains('Leave Approver'),
      expenses: roles.contains('Expense Approver'),
    );
  }

  /// المستخدم الحالي (name = رقم المستخدم) وأدواره (hrms.api.get_current_user_info)
  Future<Map<String, dynamic>> _userInfo() async {
    final msg = (await _api.getMethod(
      'hrms.api.get_current_user_info',
    ))['message'];
    return msg is Map ? Map<String, dynamic>.from(msg) : const {};
  }

  Future<String> _loggedUser() async =>
      (await _userInfo())['name']?.toString() ?? '';

  /// طلبات الإجازة المعلقة (Open، مسودة) التي المستخدم الحالي هو معتمِدها فقط
  /// (leave_approver)، فلا تظهر طلبات موظفين ليس مسؤولًا عنهم.
  Future<List<TeamLeaveRequest>> fetchTeamLeaves() async {
    final user = await _loggedUser();
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
    final user = await _loggedUser();
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

  static String _companyOf(Map<String, dynamic> emp) {
    final c = emp['company']?.toString() ?? '';
    return c.isNotEmpty ? c : ErpConfig.company;
  }
}
