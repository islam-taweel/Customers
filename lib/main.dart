import 'package:flutter/material.dart';

import 'screens/customer_screen.dart';

void main() {
  runApp(const DebtsApp());
}

class DebtsApp extends StatelessWidget {
  const DebtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر الديون',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      // فرض الاتجاه من اليمين لليسار على التطبيق كله
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const CustomersScreen(),
    );
  }
}