String _s(Object? v) => v?.toString() ?? '';
DateTime? _date(Object? v) => DateTime.tryParse(_s(v));

/// أيام الأسبوع في Event: الفهرس + 1 = DateTime.weekday (1 الإثنين … 7 الأحد)
const weekdayFields = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// «YYYY-MM-DD HH:MM:SS» (24 ساعة) كما يقبلها ERPNext
String erpDateTime(DateTime d) =>
    '${erpDate(d)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

String erpDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// مدة الموعد الذي لا وقت نهاية له (لفحص التعارض)
const defaultVisitDuration = Duration(hours: 1);

String _two(int n) => n.toString().padLeft(2, '0');

/// موعد زيارة (Event من فئة Event). صف واحد لكل موعد؛ في عرض اليوم يحمل
/// [startsOn]/[endsOn] وقت هذا التكرار بعينه.
class Visit {
  final String name;
  final String subject;
  final DateTime startsOn;
  final DateTime? endsOn;

  /// Open / Completed / Closed / Cancelled
  final String status;
  final bool repeats;
  final String repeatOn;
  final DateTime? repeatTill;

  /// أيام التكرار (1 الإثنين … 7 الأحد)
  final Set<int> weekdays;
  final String description;

  /// رقم العميل من event_participants (فقط عند جلب الموعد كاملًا)
  final String customerId;

  const Visit({
    required this.name,
    required this.subject,
    required this.startsOn,
    required this.endsOn,
    required this.status,
    required this.repeats,
    required this.repeatOn,
    required this.repeatTill,
    required this.weekdays,
    required this.description,
    this.customerId = '',
  });

  static const fields = [
    'name',
    'subject',
    'starts_on',
    'ends_on',
    'status',
    'description',
    'repeat_this_event',
    'repeat_on',
    'repeat_till',
    ...weekdayFields,
  ];

  bool get isCancelled => status == 'Cancelled';
  bool get isCompleted => status == 'Completed';
  bool get isClosed => isCancelled || isCompleted || status == 'Closed';
  bool get isWeekly => repeats && repeatOn == 'Weekly';

  /// وقت النهاية، أو ساعة بعد البداية إن لم يُحدد
  DateTime get effectiveEnd {
    final end = endsOn;
    return end != null && end.isAfter(startsOn)
        ? end
        : startsOn.add(defaultVisitDuration);
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    String customer = '';
    final participants = json['event_participants'];
    if (participants is List) {
      for (final p in participants) {
        if (p is Map && _s(p['reference_doctype']) == 'Customer') {
          customer = _s(p['reference_docname']);
          break;
        }
      }
    }
    final status = _s(json['status']);
    return Visit(
      name: _s(json['name']),
      subject: _s(json['subject']),
      startsOn: _date(json['starts_on']) ?? DateTime.now(),
      endsOn: _date(json['ends_on']),
      status: status.isEmpty ? 'Open' : status,
      repeats: '${json['repeat_this_event']}' == '1',
      repeatOn: _s(json['repeat_on']),
      repeatTill: _date(json['repeat_till']),
      weekdays: {
        for (var i = 0; i < weekdayFields.length; i++)
          if ('${json[weekdayFields[i]]}' == '1') i + 1,
      },
      description: _s(json['description']),
      customerId: customer,
    );
  }

  /// نفس الموعد بوقت تكرار محدد (من get_events)
  Visit at(DateTime start, DateTime? end) => Visit(
        name: name,
        subject: subject,
        startsOn: start,
        endsOn: end,
        status: status,
        repeats: repeats,
        repeatOn: repeatOn,
        repeatTill: repeatTill,
        weekdays: weekdays,
        description: description,
        customerId: customerId,
      );
}

/// بيانات نموذج الموعد كما تُرسل إلى ERPNext (إنشاء أو تعديل).
class VisitDraft {
  /// عنوان الموعد في ERPNext (مثل «زيارة: اسم العميل»)
  final String subject;
  final String customerId;
  final String customerName;
  final DateTime start;
  final DateTime? end;
  final String notes;
  final bool weekly;
  final Set<int> weekdays;
  final DateTime? repeatTill;

  const VisitDraft({
    required this.subject,
    required this.customerId,
    required this.customerName,
    required this.start,
    required this.end,
    required this.notes,
    required this.weekly,
    required this.weekdays,
    required this.repeatTill,
  });

  /// [forUpdate]: عند التعديل تُرسل حقول التكرار كلها (لإلغاء التكرار أو الأيام)،
  /// وعند إنشاء موعد لمرة واحدة تُترك كما يطلب الـ API.
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final days = {...weekdays, start.weekday};
    return {
      'subject': subject,
      'event_category': 'Event',
      'event_type': 'Public',
      'starts_on': erpDateTime(start),
      if (end != null) 'ends_on': erpDateTime(end!),
      if (forUpdate && end == null) 'ends_on': null,
      'description': notes.trim(),
      'repeat_this_event': weekly ? 1 : 0,
      if (weekly) ...{
        'repeat_on': 'Weekly',
        if (repeatTill != null) 'repeat_till': erpDate(repeatTill!),
        if (forUpdate && repeatTill == null) 'repeat_till': null,
        for (var i = 0; i < weekdayFields.length; i++)
          weekdayFields[i]: days.contains(i + 1) ? 1 : 0,
      } else if (forUpdate) ...{
        'repeat_on': '',
        'repeat_till': null,
        for (final f in weekdayFields) f: 0,
      },
      'event_participants': [
        {'reference_doctype': 'Customer', 'reference_docname': customerId},
      ],
    };
  }
}
