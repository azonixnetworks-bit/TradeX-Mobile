import '../../../../core/network/tradex_api_client.dart';
import '../../domain/entities/market_screener_entities.dart';
import '../../domain/repositories/market_screener_repository.dart';

final class MarketScreenerRepository
    implements MarketScreenerRepositoryContract {
  const MarketScreenerRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<MarketScreenerSnapshot> load({
    required String market,
    String stockRegion = '',
  }) async {
    final normalizedMarket = market.trim().toUpperCase();
    final normalizedRegion = stockRegion.trim().toUpperCase();
    final timeframe =
        normalizedMarket == 'STOCKS' && normalizedRegion == 'INDIA'
        ? 'D1'
        : 'H1';
    final regionQuery =
        normalizedMarket == 'STOCKS' && normalizedRegion.isNotEmpty
        ? '&region=${Uri.encodeQueryComponent(normalizedRegion)}'
        : '';
    final response = await _apiClient.getJson(
      '/api/v1/screener/results?market=${Uri.encodeQueryComponent(normalizedMarket)}'
      '&timeframe=$timeframe&sort=change_percent&order=desc$regionQuery',
    );
    final data = _map(response['data']);
    final quotes = _maps(data['results'])
        .map(MarketScreenerQuote.fromJson)
        .where((quote) => quote.symbol.isNotEmpty)
        .take(10)
        .toList(growable: false);
    return MarketScreenerSnapshot(
      market: data['market']?.toString().toUpperCase() ?? normalizedMarket,
      timeframe: data['timeframe']?.toString().toUpperCase() ?? timeframe,
      generatedAt: DateTime.tryParse(
        data['generated_at_utc']?.toString() ?? '',
      ),
      quotes: quotes,
    );
  }

  Map<String, dynamic> _map(Object? value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};

  List<Map<String, dynamic>> _maps(Object? value) => value is List
      ? value.map(_map).toList(growable: false)
      : const <Map<String, dynamic>>[];
}
