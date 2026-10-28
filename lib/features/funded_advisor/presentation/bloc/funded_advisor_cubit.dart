import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/funded_advisor_entities.dart';
import '../../domain/usecases/funded_advisor_use_cases.dart';

enum FundedAdvisorStatus {
  idle,
  cached,
  refreshing,
  fresh,
  staleOffline,
  errorNoCache,
}

class FundedAdvisorState {
  const FundedAdvisorState({
    this.status = FundedAdvisorStatus.idle,
    this.catalog,
    this.cachedAt,
    this.lastCheckedAt,
    this.lastCheckedLocalDay,
    this.selectedPartnerUuid,
    this.selectedChallengeType,
    this.selectedAccountSize,
    this.selectedPhase = 'ALL',
    this.query = '',
    this.featuredOnly = false,
    this.message,
  });

  final FundedAdvisorStatus status;
  final FundedAdvisorCatalog? catalog;
  final DateTime? cachedAt;
  final DateTime? lastCheckedAt;
  final String? lastCheckedLocalDay;
  final String? selectedPartnerUuid;
  final String? selectedChallengeType;
  final String? selectedAccountSize;
  final String selectedPhase;
  final String query;
  final bool featuredOnly;
  final String? message;

  bool get hasCatalog => catalog != null;

  FundedPartner? get selectedPartner {
    final partners = catalog?.partners ?? const <FundedPartner>[];
    for (final partner in partners) {
      if (partner.uuid == selectedPartnerUuid) return partner;
    }
    return null;
  }

  List<FundedPartner> get visiblePartners {
    final needle = query.trim().toLowerCase();
    return (catalog?.partners ?? const <FundedPartner>[])
        .where((partner) {
          if (featuredOnly && !partner.isFeatured) return false;
          if (needle.isEmpty) return true;
          return partner.name.toLowerCase().contains(needle) ||
              partner.challengeTypes.any(
                (type) => type.toLowerCase().contains(needle),
              );
        })
        .toList(growable: false);
  }

  FundedAdvisorState copyWith({
    FundedAdvisorStatus? status,
    FundedAdvisorCatalog? catalog,
    DateTime? cachedAt,
    DateTime? lastCheckedAt,
    String? lastCheckedLocalDay,
    String? selectedPartnerUuid,
    String? selectedChallengeType,
    String? selectedAccountSize,
    String? selectedPhase,
    String? query,
    bool? featuredOnly,
    String? message,
    bool clearMessage = false,
    bool clearChallengeType = false,
    bool clearAccountSize = false,
  }) => FundedAdvisorState(
    status: status ?? this.status,
    catalog: catalog ?? this.catalog,
    cachedAt: cachedAt ?? this.cachedAt,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    lastCheckedLocalDay: lastCheckedLocalDay ?? this.lastCheckedLocalDay,
    selectedPartnerUuid: selectedPartnerUuid ?? this.selectedPartnerUuid,
    selectedChallengeType: clearChallengeType
        ? null
        : selectedChallengeType ?? this.selectedChallengeType,
    selectedAccountSize: clearAccountSize
        ? null
        : selectedAccountSize ?? this.selectedAccountSize,
    selectedPhase: selectedPhase ?? this.selectedPhase,
    query: query ?? this.query,
    featuredOnly: featuredOnly ?? this.featuredOnly,
    message: clearMessage ? null : message ?? this.message,
  );
}

final class FundedAdvisorCubit extends Cubit<FundedAdvisorState> {
  FundedAdvisorCubit(this._useCases) : super(const FundedAdvisorState());

  final FundedAdvisorUseCases _useCases;
  Future<void>? _refreshInFlight;
  DateTime? _lastAttemptAt;

  FundedAdvisorUseCases get useCases => _useCases;

  Future<void> initialize() async {
    final cached = await _useCases.loadCached();
    if (isClosed) return;
    if (cached != null) {
      emit(
        state.copyWith(
          status: FundedAdvisorStatus.cached,
          catalog: cached.catalog,
          cachedAt: cached.cachedAt,
          lastCheckedAt: cached.lastCheckedAt,
          lastCheckedLocalDay: cached.lastCheckedLocalDay,
          clearMessage: true,
        ),
      );
    }
    await refreshIfDue();
  }

  Future<void> refreshIfDue({bool manual = false}) {
    final running = _refreshInFlight;
    if (running != null) return running;
    final now = DateTime.now();
    if (!manual) {
      final lastAttempt = _lastAttemptAt;
      if (lastAttempt != null && now.difference(lastAttempt).inMinutes < 5) {
        return Future<void>.value();
      }
      if (state.hasCatalog && state.lastCheckedLocalDay == _localDay(now)) {
        return Future<void>.value();
      }
    }
    _lastAttemptAt = now;
    final operation = _refresh(now, forceCatalog: manual);
    _refreshInFlight = operation;
    return operation.whenComplete(() {
      if (identical(_refreshInFlight, operation)) _refreshInFlight = null;
    });
  }

  Future<void> _refresh(DateTime now, {required bool forceCatalog}) async {
    emit(
      state.copyWith(
        status: FundedAdvisorStatus.refreshing,
        clearMessage: true,
      ),
    );
    try {
      final serverVersion = await _useCases.fetchVersion();
      var catalog = state.catalog;
      if (forceCatalog || catalog == null || catalog.version != serverVersion) {
        catalog = await _useCases.fetchCatalog();
        if (catalog.version != serverVersion) {
          throw const FormatException('Catalog version did not match.');
        }
      }
      await _useCases.saveCatalog(catalog, checkedAt: now);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: FundedAdvisorStatus.fresh,
          catalog: catalog,
          cachedAt: now.toUtc(),
          lastCheckedAt: now.toUtc(),
          lastCheckedLocalDay: _localDay(now),
          clearMessage: true,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: state.hasCatalog
              ? FundedAdvisorStatus.staleOffline
              : FundedAdvisorStatus.errorNoCache,
          message: state.hasCatalog
              ? 'Saved funded rules are shown. Connect to refresh updates.'
              : 'Funded advisor data is unavailable. Check your connection and retry.',
        ),
      );
    }
  }

  void setQuery(String value) => emit(state.copyWith(query: value));

  void setFeaturedOnly(bool value) => emit(state.copyWith(featuredOnly: value));

  void selectPartner(FundedPartner partner) => emit(
    state.copyWith(
      selectedPartnerUuid: partner.uuid,
      selectedPhase: 'ALL',
      clearChallengeType: true,
      clearAccountSize: true,
    ),
  );

  void selectChallengeType(String value) =>
      emit(state.copyWith(selectedChallengeType: value));

  void selectAccountSize(String value) =>
      emit(state.copyWith(selectedAccountSize: value));

  void selectPhase(String value) => emit(state.copyWith(selectedPhase: value));
}

String _localDay(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
