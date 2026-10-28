import '../../../../core/network/tradex_api_client.dart';
import '../../../../core/offline/offline_cache_store.dart';
import '../models/funded_advisor_models.dart';

class FundedAdvisorLocalSnapshot {
  const FundedAdvisorLocalSnapshot({
    required this.catalog,
    required this.cachedAt,
    required this.lastCheckedAt,
    required this.lastCheckedLocalDay,
  });

  final FundedAdvisorCatalogModel catalog;
  final DateTime cachedAt;
  final DateTime? lastCheckedAt;
  final String? lastCheckedLocalDay;
}

abstract interface class FundedAdvisorLocalDataSource {
  Future<FundedAdvisorLocalSnapshot?> read();

  Future<void> write(
    FundedAdvisorCatalogModel catalog, {
    required DateTime checkedAt,
  });
}

final class DiskFundedAdvisorLocalDataSource
    implements FundedAdvisorLocalDataSource {
  DiskFundedAdvisorLocalDataSource(this._apiClient, this._store);

  static const _requestKey = 'funded-advisor:catalog:v1';

  final TradeXApiClient _apiClient;
  final OfflineCacheStore _store;

  @override
  Future<FundedAdvisorLocalSnapshot?> read() async {
    final accountKey = await _apiClient.currentAccountStorageKey();
    if (accountKey == null) return null;
    final entry = await _store.get(
      accountKey: accountKey,
      requestKey: _requestKey,
    );
    if (entry == null) return null;
    try {
      final rawCatalog = entry.payload['catalog'];
      if (rawCatalog is! Map) return null;
      return FundedAdvisorLocalSnapshot(
        catalog: FundedAdvisorCatalogModel.fromJson(
          Map<String, dynamic>.from(rawCatalog),
        ),
        cachedAt: entry.cachedAt,
        lastCheckedAt: DateTime.tryParse(
          entry.payload['last_checked_at']?.toString() ?? '',
        ),
        lastCheckedLocalDay: entry.payload['last_checked_local_day']
            ?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
    FundedAdvisorCatalogModel catalog, {
    required DateTime checkedAt,
  }) async {
    final accountKey = await _apiClient.currentAccountStorageKey();
    if (accountKey == null) return;
    await _store.put(
      accountKey: accountKey,
      requestKey: _requestKey,
      payload: <String, dynamic>{
        'catalog': catalog.toJson(),
        'last_checked_at': checkedAt.toUtc().toIso8601String(),
        'last_checked_local_day': _localDay(checkedAt.toLocal()),
      },
      maxAge: const Duration(days: 365),
    );
  }
}

String _localDay(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
