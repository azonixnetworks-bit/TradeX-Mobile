import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/activity/activity_tracking_scope.dart';
import '../../../core/domain/app_platform.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../market/market.dart';
import '../domain/entities/trade_idea_entities.dart';
import '../domain/repositories/trade_idea_repository.dart';
import '../domain/usecases/tradingview_symbol_resolver.dart';
import 'bloc/trade_idea_details_cubit.dart';

part 'trade_idea_details/trade_idea_header.dart';
part 'trade_idea_details/trade_idea_chart.dart';
part 'trade_idea_details/trade_idea_detail_widgets.dart';

class TradeIdeaDetailsScreen extends StatelessWidget {
  const TradeIdeaDetailsScreen({
    super.key,
    required this.repository,
    required this.uuid,
  });

  final TradeIdeaRepositoryContract repository;
  final String uuid;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        TradeIdeaDetailsCubit(repository: repository, uuid: uuid)..load(),
    child: ActivityTrackedScreen(
      module: 'trade_ideas',
      eventName: 'signal_viewed',
      subjectId: uuid,
      child: _TradeIdeaDetailsView(repository: repository),
    ),
  );
}

class _TradeIdeaDetailsView extends StatelessWidget {
  const _TradeIdeaDetailsView({required this.repository});
  final TradeIdeaRepositoryContract repository;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    body: SafeArea(
      child: BlocConsumer<TradeIdeaDetailsCubit, TradeIdeaDetailsState>(
        listenWhen: (previous, current) =>
            previous.reactionMessage != current.reactionMessage &&
            current.reactionMessage != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.reactionMessage!))),
        builder: (context, state) {
          if (state.status == TradeIdeaLoadStatus.loading ||
              state.status == TradeIdeaLoadStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: TradeXColors.goldBright),
            );
          }
          if (state.status == TradeIdeaLoadStatus.failure ||
              state.detail == null) {
            return _LoadFailure(
              message: state.message ?? 'Trade Idea is unavailable.',
              onRetry: context.read<TradeIdeaDetailsCubit>().load,
            );
          }
          final detail = state.detail!;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(detail: detail, repository: repository),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
                sliver: SliverList.list(
                  children: [
                    _ChartPanel(detail: detail, state: state),
                    const SizedBox(height: 12),
                    _TradeSetup(detail: detail),
                    if (detail.analysis.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Panel(
                        title: 'Analysis',
                        icon: Icons.article_outlined,
                        child: Text(
                          detail.analysis,
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if (detail.timeline.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Timeline(items: detail.timeline),
                    ],
                    if (detail.close.outcome != null) ...[
                      const SizedBox(height: 12),
                      _ClosePanel(close: detail.close),
                    ],
                    const SizedBox(height: 12),
                    _SocialBar(detail: detail),
                    const SizedBox(height: 12),
                    _PrimaryActions(detail: detail, repository: repository),
                    const SizedBox(height: 16),
                    Text(
                      detail.riskNotice,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
