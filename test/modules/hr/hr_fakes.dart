import '../support/fakes.dart';

/// ردود ERPNext المشتركة لاختبارات HR: الموظف الحالي ووردية Shift Type.
/// [extra] يرد على بقية الطلبات (null = {'data': []}).
Object? hrReply(Sent r, {Object? Function(Sent r)? extra, bool linked = true}) {
  if (r.pathText.endsWith('hrms.api.get_current_employee_info')) {
    return {
      'message': linked
          ? {
              'name': 'HR-EMP-0007',
              'employee_name': 'Ahmad Saleh',
              'company': 'Ramallah Tools Co.',
            }
          : {},
    };
  }
  if (r.pathText == 'api/resource/Shift Type/Morning') {
    return {
      'data': {
        'name': 'Morning',
        'start_time': '8:00:00',
        'end_time': '16:00:00',
      },
    };
  }
  final out = extra?.call(r);
  return out ?? {'data': []};
}
