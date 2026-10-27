import '../../../core/network/tradex_api_client.dart';

/// Customer Support (S3) remains unavailable until Laravel publishes its
/// authenticated Phase-1 contract. Keeping this state explicit prevents the
/// app from inventing endpoints, ticket records, queue data, or chat presence.
class SupportRepository {
  const SupportRepository(this.apiClient);

  final TradeXApiClient apiClient;

  static const bool phaseOneAvailable = false;
  static const String unavailableMessage =
      'Secure Support is being connected to the TradeX server. Ticket and live '
      'chat data are not available yet.';
}
