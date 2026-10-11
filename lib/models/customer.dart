class Customer {
  final int? id;
  final String name;
  final String phone;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
    );
  }

  Customer copyWith({int? id, String? name, String? phone}) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, phone: $phone)';
}