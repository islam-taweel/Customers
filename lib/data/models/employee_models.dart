String _s(Object? v) => v?.toString() ?? '';

/// وردية الموظف (Shift Type): الاسم ووقتا البداية والنهاية «HH:MM:SS».
class EmployeeShift {
  final String name;
  final String startTime;
  final String endTime;

  const EmployeeShift({
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory EmployeeShift.fromJson(Map<String, dynamic> json) => EmployeeShift(
        name: _s(json['name']),
        startTime: _s(json['start_time']),
        endTime: _s(json['end_time']),
      );
}

/// الموظف المرتبط بالمستخدم الحالي (Employee.user_id).
class EmployeeProfile {
  /// الرقم الوظيفي (Employee.name، مثل HR-EMP-00001)
  final String id;
  final String name;
  final String department;
  final String designation;
  final String email;
  final String phone;

  /// مسار الصورة في ERPNext («/files/…»)، فارغ إن لم توجد
  final String image;
  final String defaultShift;
  final EmployeeShift? shift;

  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    required this.email,
    required this.phone,
    required this.image,
    required this.defaultShift,
    this.shift,
  });

  static const fields = [
    'name',
    'employee_name',
    'image',
    'department',
    'designation',
    'prefered_email',
    'company_email',
    'personal_email',
    'user_id',
    'cell_number',
    'default_shift',
  ];

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    // البريد المفضّل، ثم بريد الشركة، ثم الشخصي، ثم المستخدم نفسه
    final email = [
      json['prefered_email'],
      json['company_email'],
      json['personal_email'],
      json['user_id'],
    ].map(_s).firstWhere((e) => e.isNotEmpty, orElse: () => '');
    return EmployeeProfile(
      id: _s(json['name']),
      name: _s(json['employee_name']),
      department: _s(json['department']),
      designation: _s(json['designation']),
      email: email,
      phone: _s(json['cell_number']),
      image: _s(json['image']),
      defaultShift: _s(json['default_shift']),
    );
  }

  EmployeeProfile withShift(EmployeeShift? shift) => EmployeeProfile(
        id: id,
        name: name,
        department: department,
        designation: designation,
        email: email,
        phone: phone,
        image: image,
        defaultShift: defaultShift,
        shift: shift,
      );
}

/// بصمة (Employee Checkin): IN أو OUT ووقتها بتوقيت فلسطين
class EmployeeCheckin {
  final String name;
  final bool isIn;
  final DateTime time;

  const EmployeeCheckin({
    required this.name,
    required this.isIn,
    required this.time,
  });

  static const fields = ['name', 'log_type', 'time'];

  factory EmployeeCheckin.fromJson(Map<String, dynamic> json) =>
      EmployeeCheckin(
        name: _s(json['name']),
        isIn: _s(json['log_type']) == 'IN',
        time: DateTime.tryParse(_s(json['time'])) ?? DateTime(0),
      );
}
