import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// جلسة دخول المستخدم: قيمة كوكي `sid` فقط (واسمه الكامل للعرض).
/// تُحفظ في التخزين الآمن للجهاز (Keychain / Keystore)، وتُنسخ في الذاكرة
/// حتى يقرأها كل طلب دون انتظار. **كلمة المرور لا تُحفظ في أي مكان أبدًا.**
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _sidKey = 'erp_session_sid';
  static const _nameKey = 'erp_session_full_name';

  String? _sid;
  String? _fullName;

  String? get sid => _sid;
  String? get fullName => _fullName;
  bool get hasSession => _sid != null && _sid!.isNotEmpty;

  /// يُستدعى مرة واحدة عند بدء التطبيق، قبل أول طلب.
  Future<void> load() async {
    try {
      _sid = await _storage.read(key: _sidKey);
      _fullName = await _storage.read(key: _nameKey);
    } catch (e) {
      // تلف في التخزين الآمن (مثلًا بعد استعادة نسخة احتياطية): نبدأ بلا جلسة
      debugPrint('SessionStore.load failed: $e');
      _sid = null;
      _fullName = null;
    }
  }

  Future<void> save({required String sid, String? fullName}) async {
    // الذاكرة أولًا: تعمل الطلبات حتى لو تعذّرت الكتابة في التخزين
    _sid = sid;
    _fullName = fullName;
    try {
      await _storage.write(key: _sidKey, value: sid);
      if (fullName != null && fullName.isNotEmpty) {
        await _storage.write(key: _nameKey, value: fullName);
      } else {
        await _storage.delete(key: _nameKey);
      }
    } catch (e) {
      debugPrint('SessionStore.save failed: $e');
    }
  }

  /// حذف الكوكي (تسجيل الخروج أو انتهاء الجلسة).
  Future<void> clear() async {
    _sid = null;
    _fullName = null;
    try {
      await _storage.delete(key: _sidKey);
      await _storage.delete(key: _nameKey);
    } catch (e) {
      debugPrint('SessionStore.clear failed: $e');
    }
  }
}
