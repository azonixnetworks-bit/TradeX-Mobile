import 'dart:typed_data';

import '../../../../core/network/tradex_api_client.dart';
import '../models/funded_advisor_models.dart';

abstract interface class FundedAdvisorRemoteDataSource {
  Future<String> fetchVersion();

  Future<FundedAdvisorCatalogModel> fetchCatalog();

  Future<Uint8List> loadLogo(String path);
}

final class ApiFundedAdvisorRemoteDataSource
    implements FundedAdvisorRemoteDataSource {
  const ApiFundedAdvisorRemoteDataSource(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<String> fetchVersion() async {
    final payload = await _apiClient.getJson(
      '/api/v1/funded-account-advisor/version',
    );
    final data = _data(payload);
    final version = data['version']?.toString().trim();
    if (version == null || version.isEmpty) {
      throw const FormatException('Funded advisor version is missing.');
    }
    return version;
  }

  @override
  Future<FundedAdvisorCatalogModel> fetchCatalog() async {
    final payload = await _apiClient.getJson(
      '/api/v1/funded-account-advisor/catalog',
    );
    return FundedAdvisorCatalogModel.fromJson(_data(payload));
  }

  @override
  Future<Uint8List> loadLogo(String path) => _apiClient.getBytes(path);
}

Map<String, dynamic> _data(Map<String, dynamic> payload) {
  final data = payload['data'];
  if (data is! Map) {
    throw const FormatException('Funded advisor response is invalid.');
  }
  return Map<String, dynamic>.from(data);
}
