/// بيانات عميل جديد كما أدخلها المستخدم في نافذة الإضافة.
class NewCustomer {
  final String name;
  final String phone;

  /// عملة حساب العميل (تُرسل كـ default_currency)
  final String currency;

  /// Company أو Individual
  final String type;

  /// مجموعة العملاء والمنطقة من ERPNext (null = لم تُحمَّل القائمتان، فيُحفظ محليًا)
  final String? group;
  final String? territory;

  const NewCustomer({
    required this.name,
    required this.phone,
    required this.currency,
    this.type = 'Company',
    this.group,
    this.territory,
  });

  /// هل البيانات كافية لإنشائه في ERPNext؟
  bool get canCreateInErp =>
      (group ?? '').isNotEmpty && (territory ?? '').isNotEmpty;
}
