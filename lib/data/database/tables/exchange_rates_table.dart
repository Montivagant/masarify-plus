import 'package:drift/drift.dart';

// Cached exchange rates (optional, not required for offline core features).
class ExchangeRates extends Table {
  TextColumn get baseCurrency =>
      text().withLength(min: 3, max: 3)();
  TextColumn get targetCurrency =>
      text().withLength(min: 3, max: 3)();
  RealColumn get rate => real()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {baseCurrency, targetCurrency};
}
