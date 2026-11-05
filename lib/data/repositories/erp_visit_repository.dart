import 'package:flutter/foundation.dart';

import '../api/erp_api_client.dart';
import '../models/erp_customer.dart';
import '../models/visit_models.dart';
import 'erp_customer_repository.dart';

/// مواعيد زيارات العملاء في ERPNext (Event من فئة Event، والعميل في
/// event_participants): الإنشاء والتعديل والإنجاز والإلغاء والحذف، وقائمة
/// المواعيد، وتكرارات يوم محدد (get_events).
class ErpVisitRepository {
  ErpVisitRepository(this._api, this._customers);

  final ErpApiClient _api;
  final ErpCustomerRepository _customers;

  static const _doctype = 'Event';

  /// حد آمن لطول رابط فلتر `in`
  static const _chunk = 100;

  /// العملاء لاختيار عميل الموعد (أو النسخة المحلية دون اتصال)، مرتبون بالاسم.
  Future<List<ErpCustomer>> fetchCustomers() async {
    final list = await _customers.fetchCustomersOrLocal();
    return [...list]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // ───────────────────────── 3) التكرارات في فترة ─────────────────────────

  /// مواعيد يوم [day].
  Future<List<Visit>> fetchDay(DateTime day) => fetchRange(day, day);

  /// كل التكرارات من [from] إلى [to] (شاملة): الموعد الأسبوعي يأتي مرة لكل
  /// تكرار في الفترة. الحالة وبقية الحقول تُقرأ من Event نفسه، ويُستبعد ما ليس
  /// من فئة Event. مرتبة بوقت البداية.
  Future<List<Visit>> fetchRange(DateTime from, DateTime to) async {
    final response = await _api.getMethod(
      'frappe.desk.doctype.event.event.get_events',
      {'start': erpDate(from), 'end': erpDate(to)},
    );
    final message = response['message'];
    final rows = [
      if (message is List)
        for (final r in message)
          if (r is Map) Map<String, dynamic>.from(r),
    ];
    if (rows.isEmpty) return const [];

    final names = {for (final r in rows) r['name']?.toString() ?? ''}
      ..remove('');
    final visits = <String, Visit>{};
    final list = names.toList();
    for (var i = 0; i < list.length; i += _chunk) {
      final part =
          list.sublist(i, i + _chunk > list.length ? list.length : i + _chunk);
      final docs = await _api.getAll(
        _doctype,
        fields: Visit.fields,
        filters: [
          ['name', 'in', part],
          ['event_category', '=', 'Event'],
        ],
      );
      for (final d in docs) {
        final v = Visit.fromJson(d);
        visits[v.name] = v;
      }
    }

    final rangeStart = DateTime(from.year, from.month, from.day);
    final rangeEnd = DateTime(to.year, to.month, to.day + 1);
    final result = <Visit>[];
    for (final r in rows) {
      final v = visits[r['name']?.toString()];
      if (v == null) continue;
      final start = DateTime.tryParse('${r['starts_on']}') ?? v.startsOn;
      final end = DateTime.tryParse('${r['ends_on']}');
      // ما يقع خارج الفترة (يبدأ بعدها أو انتهى قبلها) لا يظهر
      if (!start.isBefore(rangeEnd)) continue;
      if ((end ?? start).isBefore(rangeStart)) continue;
      result.add(v.at(start, end));
    }
    result.sort((a, b) => a.startsOn.compareTo(b.startsOn));
    return result;
  }

  // ───────────────────────── منع التعارض ─────────────────────────

  /// أول موعد غير ملغى يتداخل وقته مع [draft] (أي عميل كان)، أو null.
  /// الموعد الأسبوعي يُفحص في كل تكرار حتى نهاية التكرار، أو لسنة إن لم تكن له
  /// نهاية. [exclude]: الموعد نفسه عند التعديل. الموعد بلا وقت نهاية = ساعة.
  Future<Visit?> findConflict(VisitDraft draft, {String? exclude}) async {
    final s0 = draft.start;
    final e0 = draft.end;
    final duration = (e0 != null && e0.isAfter(s0))
        ? e0.difference(s0)
        : defaultVisitDuration;
    final from = DateTime(s0.year, s0.month, s0.day);
    final to = !draft.weekly
        ? from
        : draft.repeatTill ?? DateTime(from.year + 1, from.month, from.day);
    if (to.isBefore(from)) return null;

    final others = [
      for (final v in await fetchRange(from, to))
        if (!v.isCancelled && v.name != exclude) v,
    ];
    if (others.isEmpty) return null;

    final days = {...draft.weekdays, s0.weekday};
    for (var day = from;
        !day.isAfter(to);
        day = DateTime(day.year, day.month, day.day + 1)) {
      if (draft.weekly ? !days.contains(day.weekday) : day != from) continue;
      final s = DateTime(day.year, day.month, day.day, s0.hour, s0.minute);
      final e = s.add(duration);
      for (final v in others) {
        if (s.isBefore(v.effectiveEnd) && v.startsOn.isBefore(e)) return v;
      }
    }
    return null;
  }

  // ───────────────────────── الموعد كاملًا ─────────────────────────

  Future<Visit> fetchVisit(String name) async =>
      Visit.fromJson(await _api.getDoc(_doctype, name));

  // ───────────────────────── 1) الإنشاء و 5) التعديل ─────────────────────────

  /// يعيد رقم الموعد (data.name).
  Future<String> create(VisitDraft draft) async {
    final created = await _api.postDoc(
      _doctype,
      draft.toJson(),
    );
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Event $name created');
    return name;
  }

  /// يُطبَّق على كل تكرارات الموعد.
  Future<void> update(String name, VisitDraft draft) => _api.putDoc(
        _doctype,
        name,
        draft.toJson(forUpdate: true),
      );

  /// Open / Completed / Closed / Cancelled. الإلغاء يُبقي الموعد في النظام.
  Future<void> setStatus(String name, String status) =>
      _api.putDoc(_doctype, name, {'status': status});

  /// حذف نهائي.
  Future<void> delete(String name) => _api.deleteDoc(_doctype, name);
}
