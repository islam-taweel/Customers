/// أقسام المزامنة الثلاثة في شاشة الإعدادات.
enum SyncSection { customers, items, invoices }

/// خطوات المزامنة التي تُبلَّغ للواجهة لعرض نصّ المرحلة الحالية.
enum SyncStep {
  customers,
  groups,
  items,
  prices,
  stock,
  saving,
  uploadingOrders,
  invoicesList,
  invoiceDetails,
}

/// حالة قسم واحد من أقسام المزامنة كما تعرضها الواجهة.
class SectionStatus {
  bool running = false;

  /// 0..1 أثناء التنفيذ (null = غير محدد)
  double? progress;

  /// نصّ المرحلة الحالية
  String? stage;

  DateTime? lastSync;

  /// عدد السجلات التي جُلبت في آخر مزامنة ناجحة
  int? count;

  /// وصف مختصر لآخر نتيجة (مثل «120 صنف في 8 مجموعات»)
  String? summary;

  String? error;

  /// تنبيه لا يعني فشل المزامنة (مثل طلبيات رفضها الخادم)
  String? warning;
}

/// نتيجة محاولة رفع الطلبيات المعلّقة.
class PushResult {
  final int sent;
  final int failed;

  /// true = تعذّر الوصول للخادم، فبقيت الطلبيات المتبقية معلّقة
  final bool offline;

  /// رسالة خطأ عامة (مفاتيح مرفوضة...) أوقفت الرفع
  final Object? error;

  const PushResult({
    this.sent = 0,
    this.failed = 0,
    this.offline = false,
    this.error,
  });

  static const nothing = PushResult();
}
