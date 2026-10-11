import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/operation_repository.dart';
import 'features/customers/controllers/customer_details_controller.dart';
import 'features/customers/controllers/customerscontroller.dart';
import 'features/customers/screens/customer_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // إبقاء الـ splash ظاهرًا إلى أن نطلب إزالته يدويًا
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // تجميع المكونات: DatabaseHelper ← repositories ← controllers
  final dbHelper = DatabaseHelper.instance;
  final customersController = CustomersController(CustomerRepository(dbHelper));
  final detailsFactory = CustomerDetailsControllerFactory(
    OperationRepository(dbHelper),
  );

  // جلب أول 20 عميل (وإجمالي الديون) قبل عرض أي شيء.
  // الـ timeout حماية فقط: إن تأخر التحميل تظهر الشاشة بمؤشر التحميل
  // بدل بقاء الـ splash إلى الأبد.
  await customersController
      .loadFirstPage()
      .timeout(AppConstants.splashTimeout, onTimeout: () {});

  runApp(
    DebtsApp(
      customersController: customersController,
      detailsFactory: detailsFactory,
    ),
  );

  // إخفاء الـ splash بعد رسم أول إطار، فتظهر شاشة العملاء مباشرة ببياناتها
  binding.addPostFrameCallback((_) => FlutterNativeSplash.remove());
}

class DebtsApp extends StatelessWidget {
  final CustomersController customersController;
  final CustomerDetailsControllerFactory detailsFactory;

  const DebtsApp({
    super.key,
    required this.customersController,
    required this.detailsFactory,
  });

  @override
  Widget build(BuildContext context) {
    // فوق MaterialApp ليراها كل الشاشات
    return MultiProvider(
      providers: [
        // يعيش طوال عمر التطبيق
        ChangeNotifierProvider<CustomersController>.value(
          value: customersController,
        ),
        // ينشئ متحكمًا جديدًا لكل عميل يُفتح
        Provider<CustomerDetailsControllerFactory>.value(value: detailsFactory),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // فرض الاتجاه من اليمين لليسار على التطبيق كله
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const CustomersScreen(),
      ),
    );
  }
}