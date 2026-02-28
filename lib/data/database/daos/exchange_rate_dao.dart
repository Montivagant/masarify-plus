import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exchange_rates_table.dart';

part 'exchange_rate_dao.g.dart';

@DriftAccessor(tables: [ExchangeRates])
class ExchangeRateDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRateDaoMixin {
  ExchangeRateDao(super.db);

  Future<ExchangeRate?> getRate(String base, String target) =>
      (select(exchangeRates)
            ..where(
              (r) =>
                  r.baseCurrency.equals(base) & r.targetCurrency.equals(target),
            ))
          .getSingleOrNull();

  Future<List<ExchangeRate>> getAllForBase(String base) =>
      (select(exchangeRates)
            ..where((r) => r.baseCurrency.equals(base)))
          .get();

  Future<void> upsertRate(ExchangeRatesCompanion entry) =>
      into(exchangeRates).insertOnConflictUpdate(entry);

  Future<int> clearAll() => delete(exchangeRates).go();
}
