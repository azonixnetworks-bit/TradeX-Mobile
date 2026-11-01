import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/tradex_api_client.dart';
import '../../domain/repositories/affiliate_repository.dart';

class AffiliateRepositoryImpl implements AffiliateRepository {
  AffiliateRepositoryImpl(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<JsonMap> overview() => _get('/api/v1/affiliate/overview');

  @override
  Future<JsonMap> referrals({
    int page = 1,
    int perPage = 20,
    String search = '',
    String? qualification,
  }) {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    if (qualification != null) {
      query['qualification'] = qualification;
    }
    return _get(
      '/api/v1/affiliate/referrals?${Uri(queryParameters: query).query}',
    );
  }

  @override
  Future<JsonMap> commissions({int page = 1, int perPage = 20}) =>
      _get('/api/v1/affiliate/commissions?page=$page&per_page=$perPage');

  @override
  Future<JsonMap> earningsSeries({int months = 12}) =>
      _get('/api/v1/affiliate/earnings-series?months=$months');

  @override
  Future<JsonMap> stages() => _get('/api/v1/affiliate/stages');

  @override
  Future<JsonMap> milestones() => _get('/api/v1/affiliate/milestones');

  @override
  Future<JsonMap> payoutSummary() => _get('/api/v1/payouts/summary');

  @override
  Future<JsonMap> payoutMethods() => _get('/api/v1/payouts/methods');

  @override
  Future<JsonMap> payoutHistory({int page = 1, int perPage = 20}) =>
      _get('/api/v1/payouts/history?page=$page&per_page=$perPage');

  @override
  Future<JsonMap> shareAction(String channel) async {
    try {
      final response = await _apiClient.postJson(
        '/api/v1/affiliate/share-action',
        {'channel': channel},
      );
      return AffiliateRepository.dataOf(response);
    } on ApiException catch (error) {
      throw AffiliateException(message: error.message, code: error.code);
    }
  }

  @override
  Future<JsonMap> requestPayout({
    required String method,
    required String amount,
  }) async {
    try {
      final response = await _apiClient.postJsonWithHeaders(
        '/api/v1/payouts',
        {'method': method, 'amount': amount},
        {'Idempotency-Key': const Uuid().v4()},
      );
      return AffiliateRepository.dataOf(response);
    } on ApiException catch (error) {
      throw AffiliateException(message: error.message, code: error.code);
    }
  }

  Future<JsonMap> _get(String path) async {
    try {
      final response = await _apiClient.getJson(path);
      return AffiliateRepository.dataOf(response);
    } on ApiException catch (error) {
      throw AffiliateException(message: error.message, code: error.code);
    }
  }
}
