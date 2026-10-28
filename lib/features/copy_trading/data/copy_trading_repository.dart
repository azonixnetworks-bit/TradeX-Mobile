@Deprecated(
  'Import Copy Trading domain contracts or data implementations directly.',
)
library;

export '../domain/entities/copy_trading_entities.dart';
export '../domain/repositories/copy_trading_repository.dart';
export 'datasources/copy_trading_intent_store.dart';
export 'models/copy_trading_models.dart';
export 'repositories/copy_trading_repository_impl.dart';
