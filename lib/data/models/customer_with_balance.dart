import 'customer.dart';

/// عميل مع رصيده الحالي (موجب = مستحق عليه)
class CustomerWithBalance {
  final Customer customer;
  final double balance;

  const CustomerWithBalance({required this.customer, required this.balance});

  factory CustomerWithBalance.fromMap(Map<String, dynamic> map) {
    return CustomerWithBalance(
      customer: Customer.fromMap(map),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}