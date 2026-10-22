import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/erp_api_client.dart';
import 'erp_cache_store.dart';

/// القوائم المرجعية من ERPNext: العملات وطرق الدفع.
/// كل رد ناجح يُحفظ محليًا، وعند انقطاع الاتصال تُقرأ النسخة المحفوظة.
class ErpLookupRepository {
  ErpLookupRepository(this._api, this._cache);

  final ErpApiClient _api;
  final ErpCacheStore _cache;

  static const _currenciesKey = 'lookup:currencies';
  static const _modesKey = 'lookup:modes_of_payment';

  /// العملات المفعّلة (Currency.enabled = 1).
  Future<List<String>> fetchCurrencies() => _fetch(
        key: _currenciesKey,
        doctype: 'Currency',
        filters: [
          ['enabled', '=', 1],
        ],
      );

  /// طرق الدفع المفعّلة (Mode of Payment.enabled = 1).
  Future<List<String>> fetchModesOfPayment() => _fetch(
        key: _modesKey,
        doctype: 'Mode of Payment',
        filters: [
          ['enabled', '=', 1],
        ],
      );

  /// مجموعات العملاء النهائية (Customer Group.is_group = 0).
  Future<List<String>> fetchCustomerGroups() => _fetch(
        key: 'lookup:customer_groups',
        doctype: 'Customer Group',
        filters: [
          ['is_group', '=', 0],
        ],
      );

  /// المناطق النهائية (Territory.is_group = 0).
  Future<List<String>> fetchTerritories() => _fetch(
        key: 'lookup:territories',
        doctype: 'Territory',
        filters: [
          ['is_group', '=', 0],
        ],
      );

  Future<List<String>> _fetch({
    required String key,
    required String doctype,
    required List<List<Object>> filters,
  }) async {
    // أثناء انقطاع معروف نقرأ المحفوظ مباشرة دون انتظار المهلة
    if (_api.recentlyUnreachable) {
      final cached = await _readCached(key);
      if (cached.isNotEmpty) return cached;
    }

    try {
      final rows = await _api.getAll(
        doctype,
        fields: ['name'],
        filters: filters,
      );
      final names = [
        for (final row in rows)
          if ((row['name']?.toString() ?? '').isNotEmpty) row['name'].toString(),
      ]..sort();
      if (names.isNotEmpty) await _cache.write(key, jsonEncode(names));
      return names;
    } on ErpApiException catch (e) {
      if (e.type == ErpErrorType.network) {
        final cached = await _readCached(key);
        if (cached.isNotEmpty) return cached;
      }
      rethrow;
    }
  }

  Future<List<String>> _readCached(String key) async {
    final entry = await _cache.read(key);
    if (entry == null) return const [];
    try {
      return [for (final v in jsonDecode(entry.json) as List) v.toString()];
    } catch (e) {
      debugPrint('ErpLookupRepository: نسخة محفوظة تالفة ($key): $e');
      return const [];
    }
  }
}
