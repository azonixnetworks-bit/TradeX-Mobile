import '../../domain/repositories/investment_repository.dart';
import '../datasources/investment_preferences_data_source.dart';

final class InvestmentPreferencesRepositoryImpl
    implements InvestmentPreferencesRepository {
  const InvestmentPreferencesRepositoryImpl(this._dataSource);

  final InvestmentPreferencesDataSource _dataSource;

  @override
  Future<bool> hideValues() => _dataSource.hideValues();

  @override
  Future<void> setHideValues(bool value) => _dataSource.setHideValues(value);
}
