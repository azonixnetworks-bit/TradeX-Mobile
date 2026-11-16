import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../domain/trade_ideas_repository.dart';
import '../../trade_ideas/domain/repositories/trade_idea_repository.dart';

class TradeIdeasRepository implements DashboardTradeIdeasRepository {
  TradeIdeasRepository(this._apiClient, this.detailsRepository);

  final TradeXApiClient _apiClient;
  static const _chartCacheLifetime = Duration(days: 7);
  static Future<void>? _chartCacheCleanup;
  TradeXApiClient get apiClient => _apiClient;
  @override
  final TradeIdeaRepositoryContract detailsRepository;

  @override
  Future<List<DashboardTradeIdea>> latestThree() => _latest(perPage: 12);

  @override
  Future<List<DashboardTradeIdea>> latestCrypto({int limit = 5}) =>
      _latest(perPage: limit.clamp(1, 20).toInt(), category: 'CRYPTO');

  @override
  Future<List<DashboardTradeIdea>> latestByCategory(
    String category, {
    int limit = 50,
  }) => _latest(
    perPage: limit.clamp(1, 100).toInt(),
    category: category.toUpperCase(),
  );

  @override
  Future<List<DashboardTradeIdeaCategory>> categories() async {
    try {
      final response = await _apiClient.getJson(
        '/api/v1/trade-ideas/categories',
      );
      final data = response['data'];
      final raw = data is Map ? data['categories'] ?? data['items'] : data;
      if (raw is List) {
        final categories = raw
            .whereType<Map>()
            .map(
              (item) => DashboardTradeIdeaCategory.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.slug.isNotEmpty && item.label.isNotEmpty)
            .toList(growable: false);
        if (categories.isNotEmpty) return categories;
      }
    } on ApiException {
      // The legacy fallback remains available during backend rollout.
    }
    return _fallbackCategories();
  }

  Future<List<DashboardTradeIdeaCategory>> _fallbackCategories() async {
    const defaults = <(String, String)>[
      ('FOREX', 'Forex'),
      ('COMMODITIES', 'Commodity'),
      ('CRYPTO', 'Crypto'),
      ('STOCKS', 'Stocks'),
      ('DERIV', 'Deriv'),
      ('INDICES', 'Indices'),
    ];
    return Future.wait(
      defaults.map((item) async {
        try {
          final ideas = await latestByCategory(item.$1);
          return DashboardTradeIdeaCategory(
            slug: item.$1,
            label: item.$2,
            ideasCount: ideas.length,
            unreadCount: 0,
            latestActivityAt: ideas
                .map((idea) => idea.lastActivityAt ?? idea.publishedAt)
                .whereType<DateTime>()
                .fold<DateTime?>(
                  null,
                  (latest, value) =>
                      latest == null || value.isAfter(latest) ? value : latest,
                ),
            iconUrl: null,
            artworkUrl: null,
            regions: const [],
          );
        } catch (_) {
          return DashboardTradeIdeaCategory(
            slug: item.$1,
            label: item.$2,
            ideasCount: 0,
            unreadCount: 0,
            latestActivityAt: null,
            iconUrl: null,
            artworkUrl: null,
            regions: const [],
          );
        }
      }),
    );
  }

  @override
  Future<void> markCategoryViewed(String slug) async {
    try {
      await _apiClient.postJson(
        '/api/v1/trade-ideas/categories/${Uri.encodeComponent(slug)}/mark-viewed',
        const {},
      );
    } on ApiException {
      // Local seen-state remains the fallback until the endpoint is deployed.
    }
  }

  Future<List<DashboardTradeIdea>> _latest({
    required int perPage,
    String? category,
  }) async {
    final categoryQuery = category == null
        ? ''
        : '&category=${Uri.encodeQueryComponent(category)}';
    final index = await _apiClient.getJson(
      '/api/v1/trade-ideas?per_page=$perPage$categoryQuery',
    );
    final data = index['data'];
    final ideas = data is Map ? data['trade_ideas'] : null;
    if (ideas is! List) return const [];

    return ideas
        .whereType<Map>()
        .map(
          (idea) =>
              DashboardTradeIdea.fromJson(Map<String, dynamic>.from(idea)),
        )
        .where((idea) => idea.uuid.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<Uint8List?> chartBytes(DashboardTradeIdea idea) async {
    if (!idea.chartAvailable) return null;
    final cached = await _readCachedChart(idea.uuid);
    if (cached != null) return cached;

    try {
      final bytes = await _apiClient.getBytes(
        '/api/v1/trade-ideas/${idea.uuid}/chart',
      );
      if (bytes.isNotEmpty) await _writeCachedChart(idea.uuid, bytes);
      return bytes;
    } on ApiException {
      return null;
    }
  }

  Future<Uint8List?> _readCachedChart(String uuid) async {
    try {
      final directory = await _chartCacheDirectory();
      _chartCacheCleanup ??= _removeExpiredCharts(directory);
      await _chartCacheCleanup;
      final file = File(
        '${directory.path}${Platform.pathSeparator}${_safeChartName(uuid)}.img',
      );
      if (!await file.exists()) return null;
      final modifiedAt = await file.lastModified();
      if (DateTime.now().difference(modifiedAt) >= _chartCacheLifetime) {
        await file.delete();
        return null;
      }
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedChart(String uuid, Uint8List bytes) async {
    try {
      final directory = await _chartCacheDirectory();
      final destination = File(
        '${directory.path}${Platform.pathSeparator}${_safeChartName(uuid)}.img',
      );
      final temporary = File('${destination.path}.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
    } catch (_) {
      // A cache write failure must never hide a chart fetched from Laravel.
    }
  }

  Future<Directory> _chartCacheDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      '${support.path}${Platform.pathSeparator}trade_idea_charts',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<void> _removeExpiredCharts(Directory directory) async {
    final now = DateTime.now();
    await for (final entity in directory.list()) {
      if (entity is! File || entity.path.endsWith('.tmp')) continue;
      try {
        final modifiedAt = await entity.lastModified();
        if (now.difference(modifiedAt) >= _chartCacheLifetime) {
          await entity.delete();
        }
      } catch (_) {
        // Continue cleaning the remaining cached charts.
      }
    }
  }

  String _safeChartName(String uuid) =>
      uuid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  @override
  Future<Map<String, dynamic>> react(
    DashboardTradeIdea idea,
    String? reaction,
  ) async {
    final response = await _apiClient.putJson(
      '/api/v1/trade-ideas/${idea.uuid}/reaction',
      reaction == null ? const {} : {'reaction': reaction},
    );
    final data = response['data'];
    final summary = data is Map ? data['reaction'] : null;
    return summary is Map ? Map<String, dynamic>.from(summary) : const {};
  }
}
