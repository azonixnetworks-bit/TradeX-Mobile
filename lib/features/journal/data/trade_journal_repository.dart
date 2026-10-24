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

  Future<TradeJournalHome> home() async {
    final zone = Uri.encodeQueryComponent(await timezone());
    final response = await _apiClient.getJson(
      '/api/v1/trade-journal/home?timezone=$zone',
    );
    return TradeJournalHome.fromJson(journalData(response));
  }

  Future<TradeJournalMeta> meta() async {
    final response = await _apiClient.getJson('/api/v1/trade-journal/meta');
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
  }) async {
    final query = <String, String>{
      'timezone': await timezone(),
      'page': '$page',
      'per_page': '30',
      for (final entry in filters.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    };
    final uri = Uri(path: '/api/v1/trade-journal', queryParameters: query);
    final response = await _apiClient.getJson(uri.toString());
    return TradeJournalPage.fromJson(journalData(response));
  }

  Future<TradeJournalEntry> entry(String uuid) async {
    final zone = Uri.encodeQueryComponent(await timezone());
    final response = await _apiClient.getJson(
      '/api/v1/trade-journal/$uuid?timezone=$zone',
    );
    return TradeJournalEntry.fromJson(journalData(response));
  }

  Future<TradeJournalEntry> create(Map<String, dynamic> body) async {
    final response = await _apiClient.postJson('/api/v1/trade-journal', body);
    return TradeJournalEntry.fromJson(journalData(response));
  }

  Future<TradeJournalEntry> update(
    String uuid,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.patchJson(
      '/api/v1/trade-journal/$uuid',
      body,
    );
    return TradeJournalEntry.fromJson(journalData(response));
  }

  Future<TradeJournalEntry> open(String uuid, Map<String, dynamic> body) async {
    final response = await _apiClient.postJson(
      '/api/v1/trade-journal/$uuid/open',
      body,
    );
    return TradeJournalEntry.fromJson(journalData(response));
  }

  Future<TradeJournalEntry> close(
    String uuid,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.postJson(
      '/api/v1/trade-journal/$uuid/close',
      body,
    );
    return TradeJournalEntry.fromJson(journalData(response));
  }

  Future<void> cancel(String uuid, {String? reason}) async {
    await _apiClient.postJson('/api/v1/trade-journal/$uuid/cancel', {
      if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
    });
  }

  Future<void> delete(String uuid) =>
      _apiClient.deleteJson('/api/v1/trade-journal/$uuid');

  Future<Map<String, dynamic>> analytics({
    String period = 'month',
    DateTime? from,
    DateTime? to,
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
    return journalData(await _apiClient.getJson(uri.toString()));
  }

  Future<Map<String, dynamic>> review(String type, {DateTime? date}) async {
    final query = <String, String>{
      'timezone': await timezone(),
      if (date != null) 'date': _date(date),
    };
    final uri = Uri(
      path: '/api/v1/trade-journal/reviews/$type',
      queryParameters: query,
    );
    return journalData(await _apiClient.getJson(uri.toString()));
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
    return journalData(await _apiClient.putJson(uri.toString(), body));
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
  }

  Future<Uint8List> screenshot(String uuid, String type) =>
      _apiClient.getBytes('/api/v1/trade-journal/$uuid/screenshots/$type');

  Future<void> deleteScreenshot(String uuid, String type) =>
      _apiClient.deleteJson('/api/v1/trade-journal/$uuid/screenshots/$type');

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
