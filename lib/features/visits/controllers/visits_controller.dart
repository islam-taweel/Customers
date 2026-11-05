import 'package:flutter/foundation.dart';

import '../../../core/constants/visit_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/models/visit_models.dart';
import '../../../data/repositories/erp_visit_repository.dart';

/// رسالة الخطأ مع نص ERPNext نفسه عند أخطاء الخادم.
String _withDetail(Object e, String fallback) {
  final detail =
      e is ErpApiException && e.type == ErpErrorType.server ? e.detail : null;
  final base = describeError(e, fallback: fallback);
  return (detail == null || detail.isEmpty) ? base : '$fallback\n$detail';
}

/// ينشئ متحكمات المواعيد.
class VisitsControllerFactory {
  VisitsControllerFactory(this._repository);

  final ErpVisitRepository _repository;

  TodayVisitsController today() => TodayVisitsController(_repository);

  VisitsController list() => VisitsController(_repository);

  VisitFormController form({Visit? existing, DateTime? day}) =>
      VisitFormController(_repository, existing: existing, day: day);
}

/// إجراءات بطاقة الموعد: الإنجاز وإعادة الفتح والإلغاء والحذف، ثم إعادة التحميل.
/// كل دالة تعيد null عند النجاح أو رسالة الخطأ.
abstract class VisitActions extends ChangeNotifier {
  VisitActions(this._repository);

  final ErpVisitRepository _repository;

  bool _loading = false;
  String? _error;
  bool _disposed = false;
  final Set<String> _busy = {};

  bool get loading => _loading;
  String? get error => _error;
  bool isBusy(Visit v) => _busy.contains(v.name);

  Future<void> load();

  Future<void> _run(Future<void> Function() task) async {
    _loading = true;
    _error = null;
    _notify();
    try {
      await task();
    } catch (e) {
      debugPrint('$runtimeType.load failed: $e');
      _error = describeError(e, fallback: VisitStrings.loadFailed);
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<String?> setStatus(Visit v, String status) =>
      _act(v, () => _repository.setStatus(v.name, status));

  Future<String?> delete(Visit v) => _act(v, () => _repository.delete(v.name));

  Future<String?> _act(Visit v, Future<void> Function() action) async {
    if (_busy.contains(v.name)) return null;
    _busy.add(v.name);
    _notify();
    try {
      await action();
    } catch (e) {
      debugPrint('$runtimeType action on ${v.name} failed: $e');
      return _withDetail(e, VisitStrings.actionFailed);
    } finally {
      _busy.remove(v.name);
      _notify();
    }
    await load();
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// الرئيسية: مواعيد اليوم (كل تكرار يقع اليوم).
class TodayVisitsController extends VisitActions {
  TodayVisitsController(super.repository) {
    load();
  }

  List<Visit> _visits = const [];
  List<Visit> get visits => _visits;

  /// المواعيد النشطة (غير الملغاة) لعدّها في الترحيب
  int get activeCount => _visits.where((v) => !v.isCancelled).length;

  @override
  Future<void> load() => _run(() async {
        _visits = await _repository.fetchDay(DateTime.now());
      });
}

/// «كل المواعيد» بالتقويم: تكرارات الشهر المعروض (نقطة على كل يوم فيه موعد)،
/// ومواعيد اليوم المحدد فقط. الملغاة مخفية إلا عند طلبها.
class VisitsController extends VisitActions {
  VisitsController(super.repository) {
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    load();
  }

  late DateTime _month;
  late DateTime _selected;
  List<Visit> _visits = const [];
  bool _showCancelled = false;

  /// أول يوم في الشهر المعروض
  DateTime get month => _month;
  DateTime get selectedDay => _selected;
  bool get showCancelled => _showCancelled;

  List<Visit> get _shown =>
      [for (final v in _visits) if (_showCancelled || !v.isCancelled) v];

  /// الأيام التي فيها موعد (تاريخ بلا وقت)
  Set<DateTime> get busyDays => {for (final v in _shown) _dayOf(v.startsOn)};

  /// مواعيد اليوم المحدد فقط
  List<Visit> get dayVisits =>
      [for (final v in _shown) if (_dayOf(v.startsOn) == _selected) v];

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  void setShowCancelled(bool value) {
    _showCancelled = value;
    _notify();
  }

  void selectDay(DateTime day) {
    final d = _dayOf(day);
    _selected = d;
    if (d.year != _month.year || d.month != _month.month) {
      _month = DateTime(d.year, d.month);
      load();
    } else {
      _notify();
    }
  }

  /// [delta]: ‎-1 الشهر السابق، ‎+1 التالي. يُحدَّد أول يوم فيه (أو اليوم إن كان شهره).
  void changeMonth(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    _selected = (now.year == _month.year && now.month == _month.month)
        ? _dayOf(now)
        : _month;
    load();
  }

  @override
  Future<void> load() {
    final month = _month;
    return _run(() async {
      final rows = await _repository.fetchRange(
        month,
        DateTime(month.year, month.month + 1, 0),
      );
      if (month == _month) _visits = rows; // تغيّر الشهر أثناء التحميل
    });
  }
}

/// نموذج إنشاء موعد أو تعديله.
class VisitFormController extends ChangeNotifier {
  VisitFormController(this._repository, {this.existing, DateTime? day}) {
    final now = DateTime.now();
    final e = existing;
    if (e != null) {
      _date = DateTime(e.startsOn.year, e.startsOn.month, e.startsOn.day);
      _startMinutes = e.startsOn.hour * 60 + e.startsOn.minute;
      final end = e.endsOn;
      _endMinutes = end == null ? null : end.hour * 60 + end.minute;
      notes = e.description;
      _weekly = e.isWeekly;
      _weekdays = {...e.weekdays};
      _repeatTill = e.repeatTill;
    } else if (day != null &&
        DateTime(day.year, day.month, day.day) !=
            DateTime(now.year, now.month, now.day)) {
      // يوم آخر من التقويم: العاشرة صباحًا لمدة ساعة
      _date = DateTime(day.year, day.month, day.day);
      _startMinutes = 10 * 60;
      _endMinutes = 11 * 60;
    } else {
      // الساعة الكاملة القادمة، لمدة ساعة
      final next = now.add(const Duration(hours: 1));
      _date = DateTime(next.year, next.month, next.day);
      _startMinutes = next.hour * 60;
      _endMinutes = (_startMinutes + 60).clamp(0, 24 * 60 - 1);
    }
    _weekdays.add(_date.weekday);
    _init();
  }

  final ErpVisitRepository _repository;
  final Visit? existing;

  List<ErpCustomer> _customers = const [];
  bool _customersLoading = false;
  String? _customersError;
  bool _loadingVisit = false;
  ErpCustomer? _customer;
  late DateTime _date;
  late int _startMinutes;
  int? _endMinutes;
  bool _weekly = false;
  Set<int> _weekdays = {};
  DateTime? _repeatTill;
  bool _saving = false;
  bool _disposed = false;
  String notes = '';

  bool get isEdit => existing != null;
  List<ErpCustomer> get customers => _customers;
  bool get customersLoading => _customersLoading;
  String? get customersError => _customersError;
  bool get loadingVisit => _loadingVisit;
  ErpCustomer? get customer => _customer;
  DateTime get date => _date;
  int get startMinutes => _startMinutes;
  int? get endMinutes => _endMinutes;
  bool get weekly => _weekly;
  Set<int> get weekdays => Set.unmodifiable(_weekdays);
  DateTime? get repeatTill => _repeatTill;
  bool get saving => _saving;

  DateTime get start => _date.add(Duration(minutes: _startMinutes));
  DateTime? get end =>
      _endMinutes == null ? null : _date.add(Duration(minutes: _endMinutes!));

  List<ErpCustomer> filterCustomers(String query) {
    final q = normalizeDigits(query.trim()).toLowerCase();
    if (q.isEmpty) return _customers;
    return [
      for (final c in _customers)
        if (c.name.toLowerCase().contains(q) ||
            c.id.toLowerCase().contains(q) ||
            c.phone.contains(q))
          c,
    ];
  }

  Future<void> _init() async {
    await Future.wait([loadCustomers(), _loadExisting()]);
  }

  Future<void> loadCustomers() async {
    _customersLoading = true;
    _customersError = null;
    _notify();
    try {
      _customers = await _repository.fetchCustomers();
      _matchCustomer();
    } catch (e) {
      debugPrint('VisitFormController.loadCustomers failed: $e');
      _customersError = describeError(e, fallback: VisitStrings.loadFailed);
    } finally {
      _customersLoading = false;
      _notify();
    }
  }

  String _existingCustomerId = '';

  /// العميل من event_participants (لا يأتي في القائمة ولا في get_events)
  Future<void> _loadExisting() async {
    final e = existing;
    if (e == null) return;
    _loadingVisit = true;
    _notify();
    try {
      final full = await _repository.fetchVisit(e.name);
      _existingCustomerId = full.customerId;
      _matchCustomer();
    } catch (err) {
      debugPrint('VisitFormController.loadExisting failed: $err');
    } finally {
      _loadingVisit = false;
      _notify();
    }
  }

  void _matchCustomer() {
    if (_customer != null || _existingCustomerId.isEmpty) return;
    for (final c in _customers) {
      if (c.id == _existingCustomerId) {
        _customer = c;
        return;
      }
    }
  }

  void setCustomer(ErpCustomer c) {
    _customer = c;
    _notify();
  }

  /// يوم التاريخ الجديد يحل محل يوم التاريخ القديم في أيام التكرار.
  void setDate(DateTime d) {
    _weekdays.remove(_date.weekday);
    _date = DateTime(d.year, d.month, d.day);
    _weekdays.add(_date.weekday);
    _notify();
  }

  void setStart(int minutes) {
    final duration =
        _endMinutes == null ? null : _endMinutes! - _startMinutes;
    _startMinutes = minutes;
    // يحافظ على المدة نفسها
    if (duration != null && duration > 0) {
      _endMinutes = (minutes + duration).clamp(0, 24 * 60 - 1);
    }
    _notify();
  }

  void setEnd(int? minutes) {
    _endMinutes = minutes;
    _notify();
  }

  void setWeekly(bool value) {
    _weekly = value;
    _notify();
  }

  /// يوم التاريخ نفسه لا يُلغى تحديده.
  void toggleWeekday(int day) {
    if (day == _date.weekday) return;
    if (!_weekdays.remove(day)) _weekdays.add(day);
    _notify();
  }

  void setRepeatTill(DateTime? d) {
    _repeatTill = d;
    _notify();
  }

  /// null = صالح.
  String? validate() {
    if (_customer == null) return VisitStrings.customerRequired;
    if (_endMinutes != null && _endMinutes! <= _startMinutes) {
      return VisitStrings.endBeforeStart;
    }
    if (_weekly && _repeatTill != null && _repeatTill!.isBefore(_date)) {
      return VisitStrings.tillBeforeStart;
    }
    return null;
  }

  /// null = نجح، وإلا رسالة الخطأ.
  Future<String?> save() async {
    final invalid = validate();
    if (invalid != null) return invalid;
    final c = _customer!;
    final draft = VisitDraft(
      subject: VisitStrings.subject(c.name),
      customerId: c.id,
      customerName: c.name,
      start: start,
      end: end,
      notes: notes,
      weekly: _weekly,
      weekdays: _weekdays,
      repeatTill: _repeatTill,
    );

    _saving = true;
    _notify();
    try {
      // لا موعدين في نفس الوقت، حتى مع عميل مختلف
      final conflict =
          await _repository.findConflict(draft, exclude: existing?.name);
      if (conflict != null) {
        return VisitStrings.conflict(
          conflict.subject,
          conflict.startsOn,
          conflict.effectiveEnd,
        );
      }
      final e = existing;
      if (e == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(e.name, draft);
      }
      return null;
    } catch (err) {
      debugPrint('VisitFormController.save failed: $err');
      return _withDetail(err, VisitStrings.saveFailed);
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
