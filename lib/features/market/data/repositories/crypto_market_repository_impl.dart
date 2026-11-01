import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/tradex_api_client.dart';
import '../../domain/entities/crypto_market_entities.dart';
import '../../domain/repositories/crypto_market_repository.dart';

class CryptoMarketRepository implements CryptoMarketRepositoryContract {
  CryptoMarketRepository(this._apiClient);

  static const int bubbleAssetLimit = 50;

  final TradeXApiClient _apiClient;
  final Future<SharedPreferences> _cache = SharedPreferences.getInstance();

  @override
  Future<CryptoMarketSnapshot> load({
    required String segment,
    int page = 1,
    String search = '',
  }) async {
    final normalizedSearch = search.trim().toUpperCase();
    final futuresOnly = normalizedSearch.endsWith('.P');
    final cleanSearch = futuresOnly
        ? normalizedSearch.substring(0, normalizedSearch.length - 2)
        : normalizedSearch;
    final encodedSearch = Uri.encodeQueryComponent(cleanSearch);
    final searchBothSegments = cleanSearch.isNotEmpty && !futuresOnly;
    final primarySegment = futuresOnly ? 'FUTURES' : segment;
    final secondarySegment = primarySegment == 'SPOT' ? 'FUTURES' : 'SPOT';
    final requests = await Future.wait([
      _safeGet(
        '/api/v1/screener/bubbles?limit=100&page=1'
        '&per_page=$bubbleAssetLimit'
        '&segment=$segment&bubble_mode=GAINERS',
      ),
      _safeGet(
        '/api/v1/screener/symbols?market=CRYPTO&segment=$primarySegment'
        '&sort=VOLUME&page=$page&per_page=10&search=$encodedSearch',
      ),
      searchBothSegments
          ? _safeGet(
              '/api/v1/screener/symbols?market=CRYPTO'
              '&segment=$secondarySegment&sort=VOLUME&page=$page'
              '&per_page=10&search=$encodedSearch',
            )
          : Future.value(const <String, dynamic>{}),
    ]);
    if (requests.every((response) => response.isEmpty)) {
      throw StateError('Every crypto market endpoint failed.');
    }
    final cache = await _cache;
    unawaited(
      cache.setString(
        _cacheKey(segment, page, search),
        jsonEncode({
          'cached_at': DateTime.now().toIso8601String(),
          'data': requests,
        }),
      ),
    );
    return _parse(requests, fallbackSegment: primarySegment);
  }

  @override
  Future<CryptoMarketSnapshot?> loadCached({
    required String segment,
    int page = 1,
    String search = '',
  }) async {
    try {
      final cache = await _cache;
      final raw = cache.getString(_cacheKey(segment, page, search));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['data'] is! List) return null;
      final cachedAt = DateTime.tryParse(
        decoded['cached_at']?.toString() ?? '',
      );
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > const Duration(hours: 6)) {
        return null;
      }
      final responses = (decoded['data'] as List)
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false);
      if (responses.length != 3) return null;
      return _parse(responses, fallbackSegment: segment);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CryptoBubbleUpdate> loadBubbleUpdate({
    required String segment,
    CryptoBubbleMode mode = CryptoBubbleMode.gainers,
  }) async {
    final response = await _apiClient.getJson(
      '/api/v1/screener/bubbles?limit=100'
      '&segment=$segment&bubble_mode=${mode.apiValue}',
    );
    final data = _data(response);
    final assets = _rankBubbleAssets(
      data,
      mode: mode,
    ).map((asset) => asset.withSegment(segment)).toList(growable: false);
    final marketAssets = _maps(data['assets'])
        .map(CryptoAsset.fromJson)
        .map((asset) => asset.withSegment(segment))
        .toList(growable: false);
    if (assets.isEmpty) {
      throw StateError('Live top-gainer bubbles are unavailable.');
    }
    return CryptoBubbleUpdate(
      summary: CryptoMarketSummary.fromJson(_map(data['summary'])),
      assets: assets,
      marketAssets: marketAssets,
      generatedAt: DateTime.tryParse(
        data['generated_at_utc']?.toString() ?? '',
      ),
      stale: data['stale'] == true,
    );
  }

  @override
  Future<List<CryptoAsset>> loadWatchlist({
    required Iterable<String> symbols,
    required String segment,
  }) async {
    final normalized = symbols
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toList(growable: false);
    if (normalized.isEmpty) return const [];

    final bySymbol = <String, CryptoAsset>{};
    for (var offset = 0; offset < normalized.length; offset += 20) {
      final end = math.min(offset + 20, normalized.length);
      final batch = normalized.sublist(offset, end);
      final encodedSymbols = Uri.encodeQueryComponent(batch.join(','));
      final response = await _apiClient.getJson(
        '/api/v1/screener/results?market=CRYPTO&timeframe=H1'
        '&segment=$segment&symbols=$encodedSymbols',
      );
      final data = _data(response);
      for (final row in _maps(data['results'])) {
        final asset = CryptoAsset.fromJson(row);
        if (asset.symbol.isNotEmpty) bySymbol[asset.symbol] = asset;
      }
    }

    return [
      for (final symbol in normalized)
        if (bySymbol[symbol] != null) bySymbol[symbol]!,
    ];
  }

  CryptoMarketSnapshot _parse(
    List<Map<String, dynamic>> requests, {
    required String fallbackSegment,
  }) {
    final bubbles = _data(requests[0]);
    final primaryCatalog = _data(requests[1]);
    final secondaryCatalog = _data(requests[2]);
    final primarySegment = primaryCatalog['segment']?.toString().toUpperCase();
    final secondarySegment = secondaryCatalog['segment']
        ?.toString()
        .toUpperCase();
    final catalogAssets = <CryptoAsset>[
      for (final row in _maps(primaryCatalog['symbols']))
        CryptoAsset.fromJson(row).withSegment(
          primarySegment?.isNotEmpty == true
              ? primarySegment!
              : fallbackSegment,
        ),
      for (final row in _maps(secondaryCatalog['symbols']))
        CryptoAsset.fromJson(row).withSegment(
          secondarySegment?.isNotEmpty == true
              ? secondarySegment!
              : (fallbackSegment == 'SPOT' ? 'FUTURES' : 'SPOT'),
        ),
    ];
    final pagedBubbleAssets = _maps(bubbles['assets'])
        .map(CryptoAsset.fromJson)
        .toList(growable: false);
    final initialBubbleAssets = _maps(bubbles['bubbles'])
        .map(CryptoAsset.fromJson)
        .toList(growable: false);
    final marketAssets = initialBubbleAssets.isNotEmpty
        ? initialBubbleAssets
        : pagedBubbleAssets;
    final rankedBubbleAssets = _rankBubbleAssets(
      bubbles,
      mode: bubbles['bubble_selection']?.toString() == 'TOP_LOSERS_24H'
          ? CryptoBubbleMode.losers
          : CryptoBubbleMode.gainers,
    );
    final bubbleBySymbol = {
      for (final asset in marketAssets) asset.symbol: asset,
    };
    final enrichedCatalog = catalogAssets
        .map((asset) => asset.mergeMarket(bubbleBySymbol[asset.symbol]))
        .toList(growable: false);
    final assets = enrichedCatalog.isNotEmpty
        ? enrichedCatalog
        : pagedBubbleAssets;
    final primaryPagination = CryptoPagination.fromJson(
      _map(primaryCatalog['pagination']),
    );
    final secondaryPagination = CryptoPagination.fromJson(
      _map(secondaryCatalog['pagination']),
    );
    final parsedPagination = CryptoPagination(
      currentPage: math.max(
        primaryPagination.currentPage,
        secondaryPagination.currentPage,
      ),
      lastPage: math.max(
        primaryPagination.lastPage,
        secondaryPagination.lastPage,
      ),
      total: primaryPagination.total + secondaryPagination.total,
      hasMore: primaryPagination.hasMore || secondaryPagination.hasMore,
    );
    return CryptoMarketSnapshot(
      summary: CryptoMarketSummary.fromJson(_map(bubbles['summary'])),
      assets: assets,
      bubbleAssets: rankedBubbleAssets,
      topAssets: assets.take(10).toList(growable: false),
      generatedAt: DateTime.tryParse(
        bubbles['generated_at_utc']?.toString() ?? '',
      ),
      stale: bubbles['stale'] == true,
      pagination: parsedPagination.total > 0
          ? parsedPagination
          : CryptoPagination(
              currentPage: 1,
              lastPage: 1,
              total: assets.length,
              hasMore: false,
            ),
      partialData: requests[0].isEmpty || requests[1].isEmpty,
    );
  }

  List<CryptoAsset> _rankBubbleAssets(
    Map<String, dynamic> data, {
    required CryptoBubbleMode mode,
  }) {
    final preferred = _maps(data['bubbles'])
        .map(CryptoAsset.fromJson)
        .toList(growable: false);
    final candidates = preferred.isNotEmpty
        ? preferred
        : _maps(data['assets'])
              .map(CryptoAsset.fromJson)
              .toList(growable: false);
    final ranked = [...candidates]
      ..sort((left, right) {
        final changeOrder = mode == CryptoBubbleMode.losers
            ? left.changePercent.compareTo(right.changePercent)
            : right.changePercent.compareTo(left.changePercent);
        return changeOrder != 0
            ? changeOrder
            : right.quoteVolume.compareTo(left.quoteVolume);
      });
    return ranked.take(bubbleAssetLimit).toList(growable: false);
  }

  Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      return await _apiClient.getJson(path);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  String _cacheKey(String segment, int page, String search) {
    final query = base64Url.encode(utf8.encode(search.trim().toLowerCase()));
    return 'crypto_market_v2_${segment.toLowerCase()}_${page}_$query';
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];
}
