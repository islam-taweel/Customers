import 'customer.dart';

/// عميل مع رصيده الحالي (موجب = مستحق عليه)
class CustomerWithBalance {
  final Customer customer;
  final double balance;

  /// رقم العميل في ERPNext (null للعميل المحلي غير المرتبط)، لربطه بمستحقه من الـ API
  final String? erpId;

  const CustomerWithBalance({
    required this.customer,
    required this.balance,
    this.erpId,
  });

  factory CustomerWithBalance.fromMap(Map<String, dynamic> map) {
    return CustomerWithBalance(
      customer: Customer.fromMap(map),
      balance: (map['balance'] as num).toDouble(),
      erpId: (map['erpId'] as String?)?.isEmpty ?? true
          ? null
          : map['erpId'] as String?,
    );
  }
}