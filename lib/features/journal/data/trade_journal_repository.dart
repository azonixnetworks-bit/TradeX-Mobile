import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/network/tradex_api_client.dart';
import 'trade_journal_models.dart';

typedef TradeJournalLivePriceLoader = Future<double?> Function(String symbol);

class TradeJournalRepository {
  TradeJournalRepository(
    this._apiClient, [
    this._timezone,
    TradeJournalLivePriceLoader? livePriceLoader,
  ]) : _livePriceLoader = livePriceLoader ?? _loadBinanceSpotPrice;

  final TradeXApiClient _apiClient;
  final TradeJournalLivePriceLoader _livePriceLoader;
  String? _timezone;
  var _homeNeedsRefresh = false;
  var _entriesNeedRefresh = false;
  var _analyticsNeedsRefresh = false;
  final _entriesNeedingRefresh = <String>{};

  Future<String> timezone() async {
    final cached = _timezone;
    if (cached != null) return cached;
    try {
      _timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      _timezone = 'UTC';
    }
    return _timezone!;
  }

  Future<TradeJournalHome> home({bool forceRefresh = false}) async {
    final zone = Uri.encodeQueryComponent(await timezone());
    final path = '/api/v1/trade-journal/home?timezone=$zone';
    final shouldRefresh = forceRefresh || _homeNeedsRefresh;
    final response = await _journalGet(path, forceRefresh: shouldRefresh);
    if (shouldRefresh && !_isOfflineResponse(response)) {
      _homeNeedsRefresh = false;
    }
    return TradeJournalHome.fromJson(journalData(response));
  }

  Future<TradeJournalMeta> meta({bool forceRefresh = false}) async {
    final response = await _journalGet(
      '/api/v1/trade-journal/meta',
      forceRefresh: forceRefresh,
    );
    return TradeJournalMeta.fromJson(journalData(response));
  }

  Future<List<TradeJournalSymbolSuggestion>> symbolSuggestions({
    required String market,
    required String search,
    String? stockRegion,
  }) async {
    final query = search.trim();
    if (query.isEmpty) return const [];
    final parameters = <String, String>{
      'market': market.trim().toUpperCase(),
      'search': query.toUpperCase(),
      'page': '1',
      'per_page': '10',
      if (market.toLowerCase() == 'crypto') ...{
        'segment': 'SPOT',
        'sort': 'VOLUME',
      },
      if (market.toLowerCase() == 'stocks' &&
          stockRegion?.trim().isNotEmpty == true)
        'region': stockRegion!.trim().toUpperCase(),
    };
    final uri = Uri(
      path: '/api/v1/screener/symbols',
      queryParameters: parameters,
    );
    final data = journalData(await _apiClient.getJson(uri.toString()));
    return journalMaps(data['symbols'])
        .map(TradeJournalSymbolSuggestion.fromJson)
        .where((item) => item.symbol.isNotEmpty)
        .toList(growable: false);
  }

  Future<double?> livePrice({
    required String market,
    required String symbol,
    String? stockRegion,
  }) async {
    final normalizedSymbol = symbol.trim().toUpperCase();
    if (normalizedSymbol.isEmpty) return null;

    try {
      final suggestions = await symbolSuggestions(
        market: market,
        search: normalizedSymbol,
        stockRegion: stockRegion,
      );
      for (final suggestion in suggestions) {
        if (suggestion.symbol == normalizedSymbol &&
            suggestion.price != null &&
            suggestion.price! > 0) {
          return suggestion.price;
        }
      }
    } catch (_) {
      // Binance remains available as the selected crypto quote fallback.
    }

    if (market.trim().toLowerCase() != 'crypto') return null;
    try {
      return await _livePriceLoader(normalizedSymbol);
    } catch (_) {
      return null;
    }
  }

  Future<TradeJournalPage> entries({
    Map<String, String> filters = const {},
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final query = <String, String>{
      'timezone': await timezone(),
      'page': '$page',
      'per_page': '30',
      for (final entry in filters.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    };
    final uri = Uri(path: '/api/v1/trade-journal', queryParameters: query);
    final shouldRefresh = forceRefresh || _entriesNeedRefresh;
    final response = await _journalGet(
      uri.toString(),
      forceRefresh: shouldRefresh,
    );
    if (shouldRefresh && !_isOfflineResponse(response)) {
      _entriesNeedRefresh = false;
    }
    return TradeJournalPage.fromJson(journalData(response));
  }

  Future<TradeJournalEntry> entry(
    String uuid, {
    bool forceRefresh = false,
  }) async {
    final zone = Uri.encodeQueryComponent(await timezone());
    final path = '/api/v1/trade-journal/$uuid?timezone=$zone';
    final shouldRefresh = forceRefresh || _entriesNeedingRefresh.contains(uuid);
    final response = await _journalGet(path, forceRefresh: shouldRefresh);
    if (shouldRefresh && !_isOfflineResponse(response)) {
      _entriesNeedingRefresh.remove(uuid);
    }
    return TradeJournalEntry.fromJson(journalData(response));
  }

  Future<TradeJournalEntry> create(Map<String, dynamic> body) async {
    final response = await _apiClient.postJson('/api/v1/trade-journal', body);
    final entry = TradeJournalEntry.fromJson(journalData(response));
    await _cacheSavedEntry(response, entry.uuid);
    _markAggregatesDirty();
    return entry;
  }

  Future<TradeJournalEntry> update(
    String uuid,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.patchJson(
      '/api/v1/trade-journal/$uuid',
      body,
    );
    final entry = TradeJournalEntry.fromJson(journalData(response));
    await _cacheSavedEntry(response, entry.uuid);
    _markAggregatesDirty();
    return entry;
  }

  Future<TradeJournalEntry> open(String uuid, Map<String, dynamic> body) async {
    final response = await _apiClient.postJson(
      '/api/v1/trade-journal/$uuid/open',
      body,
    );
    final entry = TradeJournalEntry.fromJson(journalData(response));
    await _cacheSavedEntry(response, entry.uuid);
    _markAggregatesDirty();
    return entry;
  }

  Future<TradeJournalEntry> close(
    String uuid,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.postJson(
      '/api/v1/trade-journal/$uuid/close',
      body,
    );
    final entry = TradeJournalEntry.fromJson(journalData(response));
    await _cacheSavedEntry(response, entry.uuid);
    _markAggregatesDirty();
    return entry;
  }

  Future<void> cancel(String uuid, {String? reason}) async {
    await _apiClient.postJson('/api/v1/trade-journal/$uuid/cancel', {
      if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
    });
    _entriesNeedingRefresh.add(uuid);
    _markAggregatesDirty();
  }

  Future<void> delete(String uuid) async {
    await _apiClient.deleteJson('/api/v1/trade-journal/$uuid');
    _entriesNeedingRefresh.add(uuid);
    _markAggregatesDirty();
  }

  Future<Map<String, dynamic>> analytics({
    String period = 'month',
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) async {
    final query = <String, String>{
      'timezone': await timezone(),
      'period': period,
      if (from != null) 'from': _date(from),
      if (to != null) 'to': _date(to),
    };
    final uri = Uri(
      path: '/api/v1/trade-journal/analytics',
      queryParameters: query,
    );
    final shouldRefresh = forceRefresh || _analyticsNeedsRefresh;
    final response = await _journalGet(
      uri.toString(),
      forceRefresh: shouldRefresh,
    );
    if (shouldRefresh && !_isOfflineResponse(response)) {
      _analyticsNeedsRefresh = false;
    }
    return journalData(response);
  }

  Future<Map<String, dynamic>> review(
    String type, {
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final query = <String, String>{
      'timezone': await timezone(),
      if (date != null) 'date': _date(date),
    };
    final uri = Uri(
      path: '/api/v1/trade-journal/reviews/$type',
      queryParameters: query,
    );
    return journalData(
      await _journalGet(uri.toString(), forceRefresh: forceRefresh),
    );
  }

  Future<Map<String, dynamic>> saveReview(
    String type,
    Map<String, dynamic> body, {
    DateTime? date,
  }) async {
    final query = <String, String>{
      'timezone': await timezone(),
      if (date != null) 'date': _date(date),
    };
    final uri = Uri(
      path: '/api/v1/trade-journal/reviews/$type',
      queryParameters: query,
    );
    final response = await _apiClient.putJson(uri.toString(), body);
    await _apiClient.cacheJson(uri.toString(), response);
    return journalData(response);
  }

  Future<void> uploadScreenshot(
    String uuid,
    String type,
    String filePath,
  ) async {
    await _apiClient.postMultipart(
      '/api/v1/trade-journal/$uuid/screenshots/$type',
      const {},
      {'image': filePath},
    );
    _entriesNeedingRefresh.add(uuid);
  }

  Future<Uint8List> screenshot(String uuid, String type) =>
      _apiClient.getBytes('/api/v1/trade-journal/$uuid/screenshots/$type');

  Future<void> deleteScreenshot(String uuid, String type) async {
    await _apiClient.deleteJson(
      '/api/v1/trade-journal/$uuid/screenshots/$type',
    );
    _entriesNeedingRefresh.add(uuid);
  }

  Future<Map<String, dynamic>> _journalGet(
    String path, {
    bool forceRefresh = false,
  }) => forceRefresh
      ? _apiClient.getJson(path)
      : _apiClient.getJsonCacheFirst(path);

  bool _isOfflineResponse(Map<String, dynamic> response) =>
      response['_offline_cache'] is Map;

  Future<void> _cacheSavedEntry(
    Map<String, dynamic> response,
    String uuid,
  ) async {
    if (uuid.trim().isEmpty) return;
    final zone = Uri.encodeQueryComponent(await timezone());
    await _apiClient.cacheJson(
      '/api/v1/trade-journal/$uuid?timezone=$zone',
      response,
    );
    _entriesNeedingRefresh.remove(uuid);
  }

  void _markAggregatesDirty() {
    _homeNeedsRefresh = true;
    _entriesNeedRefresh = true;
    _analyticsNeedsRefresh = true;
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

Future<double?> _loadBinanceSpotPrice(String symbol) async {
  final normalizedSymbol = symbol.trim().toUpperCase();
  if (normalizedSymbol.isEmpty) return null;
  for (final host in const ['data-api.binance.vision', 'api.binance.com']) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client
          .getUrl(
            Uri.https(host, '/api/v3/ticker/price', {
              'symbol': normalizedSymbol,
            }),
          )
          .timeout(const Duration(seconds: 7));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 7),
      );
      if (response.statusCode != HttpStatus.ok) continue;
      final payload = jsonDecode(
        await utf8.decoder
            .bind(response)
            .join()
            .timeout(const Duration(seconds: 7)),
      );
      if (payload is! Map) continue;
      final price = double.tryParse(payload['price']?.toString() ?? '');
      if (price != null && price > 0) return price;
    } catch (_) {
      // Try the next Binance public host.
    } finally {
      client.close(force: true);
    }
  }
  return null;
}
