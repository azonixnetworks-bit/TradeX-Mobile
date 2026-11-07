import 'package:flutter/material.dart';

import '../../../core/activity/activity_tracking_scope.dart';
import '../../../core/bloc/bloc_future_builder.dart';
import '../../../core/domain/api_gateway.dart';
import '../../../core/domain/user_facing_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../../../core/serialization/structured_text_codec.dart';
import '../catalog_dependencies.dart';
import '../models/feature_spec.dart';
import '../../secure_workflows/domain/services/secure_workflow_platform.dart';

part 'feature_catalog/feature_workflow_screens.dart';
part 'feature_catalog/feature_catalog_widgets.dart';

class FeatureCatalogScreen extends StatelessWidget {
  const FeatureCatalogScreen({super.key, required this.dependencies});

  final CatalogDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<FeatureSpec>>{};
    for (final spec in tradeXFeatureSpecs) {
      groups.putIfAbsent(spec.group, () => <FeatureSpec>[]).add(spec);
    }
    return _FeatureScaffold(
      title: 'TradeX Services',
      subtitle: 'Secure access to your available account services',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Services',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.6),
          ),
          const SizedBox(height: 4),
          Text(
            'Access TradeX services and secure account workflows in one place.',
            style: TextStyle(color: context.palette.secondaryText),
          ),
          const SizedBox(height: 16),
          const _SafetyNotice(),
          const SizedBox(height: 14),
          for (final entry in groups.entries) ...[
            _GroupHeading(entry.key),
            const SizedBox(height: 8),
            _FeatureGroup(
              specs: entry.value,
              onOpen: (spec) => openTradeXFeature(context, dependencies, spec),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

Future<void> openTradeXFeature(
  BuildContext context,
  CatalogDependencies dependencies,
  FeatureSpec spec,
) {
  ActivityTrackingScope.maybeOf(context)?.openedFeature(spec.id);
  if (spec.id == 'trade-journal') {
    ActivityTrackingScope.maybeOf(context)?.track('journal', 'journal_opened');
  }
  final module = switch (spec.group) {
    'Home & Market' => 'news',
    'Trade Ideas' => 'trade_ideas',
    'Copy Trading' => 'copy_trading',
    'Affiliate & Referrals' => 'affiliate',
    'Profile & Security' => 'profile',
    'Notifications & Support' => 'support',
    'Journal & Tools' =>
      spec.id == 'replay-backtesting'
          ? 'replay'
          : spec.id == 'risk-reward-calculator'
          ? 'calculator'
          : spec.id == 'funded-advisor'
          ? 'funded_accounts'
          : 'journal',
    _ => 'app',
  };
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ActivityTrackedScreen(
        module: module,
        eventName: 'screen_viewed',
        subjectId: spec.id.replaceAll('-', '_'),
        child: dependencies.buildFeature(spec),
      ),
    ),
  );
}
