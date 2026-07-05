import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/database/tables/recurring_transaction.dart';
import 'package:money_tracker/core/database/tables/transactions.dart';

part 'recurring_transactions_dao.g.dart';

@DriftAccessor(tables: [RecurringTransactions, Transactions])
class RecurringTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringTransactionsDaoMixin {
  RecurringTransactionsDao(super.db);

  Future<List<RecurringTransaction>> getAllRecurringTransactions() {
    return select(recurringTransactions).get();
  }

  Stream<List<RecurringTransaction>> watchAllRecurringTransactions() {
    return select(recurringTransactions).watch();
  }

  Stream<List<RecurringTransaction>> watchEnabledRecurringTransactions() {
    return (select(recurringTransactions)
          ..where((r) => r.enabled.equals(true)))
        .watch();
  }

  Stream<RecurringTransaction?> watchRecurringTransactionById(int id) {
    return (select(recurringTransactions)..where((r) => r.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<RecurringTransaction?> getRecurringTransactionById(int id) {
    return (select(recurringTransactions)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  Future<RecurringTransaction?> getRecurringTransactionByTransactionId(
    int transactionId,
  ) {
    return (select(recurringTransactions)
          ..where((r) => r.transactionId.equals(transactionId)))
        .getSingleOrNull();
  }

  Stream<List<RecurringTransaction>> watchByFrequency(
    RecurringFrequency frequency,
  ) {
    return (select(recurringTransactions)
          ..where((r) => r.frequency.equalsValue(frequency)))
        .watch();
  }

  /// Enabled recurring transactions whose next run is due on or before [asOf].
  Future<List<RecurringTransaction>> getDueRecurringTransactions({
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    return (select(recurringTransactions)
          ..where(
            (r) => r.enabled.equals(true) & r.nextRun.isSmallerOrEqualValue(now),
          ))
        .get();
  }

  Future<int> insertRecurringTransaction(
    RecurringTransactionsCompanion entry,
  ) {
    return into(recurringTransactions).insert(entry);
  }

  Future<bool> updateRecurringTransaction(
    RecurringTransactionsCompanion entry,
  ) {
    return update(recurringTransactions).replace(entry);
  }

  Future<int> updateNextRun(int id, DateTime nextRun) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(nextRun: Value(nextRun)));
  }

  Future<int> setEnabled(int id, bool enabled) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(enabled: Value(enabled)));
  }

  Future<int> deleteRecurringTransaction(int id) {
    return (delete(recurringTransactions)..where((r) => r.id.equals(id)))
        .go();
  }
}
