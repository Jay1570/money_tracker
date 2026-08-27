import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/accounts.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/database/tables/recurring_transaction.dart';
import 'package:money_tracker/core/models/recurring_transaction.dart';

part 'recurring_transactions_dao.g.dart';

@DriftAccessor(tables: [RecurringTransactions, Accounts, Categories])
class RecurringTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringTransactionsDaoMixin {
  RecurringTransactionsDao(super.db);

  // accountId and transferAccountId both point at Accounts, so the second
  // one needs its own aliased table — otherwise drift can't tell which
  // joined "accounts" row belongs to which FK.
  late final _account = alias(accounts, 'sourceAccount');
  late final _transferAccounts = alias(accounts, 'transferAccount');

  JoinedSelectStatement<HasResultSet, dynamic> _joinedQuery() {
    return select(recurringTransactions).join([
      innerJoin(
        _account,
        _account.id.equalsExp(recurringTransactions.accountId),
      ),
      leftOuterJoin(
        _transferAccounts,
        _transferAccounts.id.equalsExp(
          recurringTransactions.transferAccountId,
        ),
      ),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(recurringTransactions.categoryId),
      ),
    ]);
  }

  RecurringTransactionWithJoin _mapRow(TypedResult row) {
    return RecurringTransactionWithJoin(
      id: row.readTable(recurringTransactions).id,
      amount: row.readTable(recurringTransactions).amount,
      type: row.readTable(recurringTransactions).type,
      accountId: row.readTable(recurringTransactions).accountId,
      categoryId: row.readTable(recurringTransactions).categoryId,
      transferAccountId: row.readTable(recurringTransactions).transferAccountId,
      note: row.readTable(recurringTransactions).note,
      frequency: row.readTable(recurringTransactions).frequency,
      nextRun: row.readTable(recurringTransactions).nextRun,
      enabled: row.readTable(recurringTransactions).enabled,
      account: row.readTable(_account),
      transferAccount: row.readTableOrNull(_transferAccounts),
      category: row.readTableOrNull(categories),
    );
  }

  Future<List<RecurringTransactionWithJoin>> getAllRecurringTransactions() {
    return _joinedQuery().map(_mapRow).get();
  }

  Stream<List<RecurringTransactionWithJoin>> watchAllRecurringTransactions() {
    return _joinedQuery().map(_mapRow).watch();
  }

  Stream<List<RecurringTransactionWithJoin>>
  watchEnabledRecurringTransactions() {
    return (_joinedQuery()..where(recurringTransactions.enabled.equals(true)))
        .map(_mapRow)
        .watch();
  }

  Stream<RecurringTransactionWithJoin?> watchRecurringTransactionById(int id) {
    return (_joinedQuery()..where(recurringTransactions.id.equals(id)))
        .map(_mapRow)
        .watchSingleOrNull();
  }

  Future<RecurringTransactionWithJoin?> getRecurringTransactionById(int id) {
    return (_joinedQuery()..where(recurringTransactions.id.equals(id)))
        .map(_mapRow)
        .getSingleOrNull();
  }

  Stream<List<RecurringTransactionWithJoin>> watchByFrequency(
    RecurringFrequency frequency,
  ) {
    return (_joinedQuery()
          ..where(recurringTransactions.frequency.equalsValue(frequency)))
        .map(_mapRow)
        .watch();
  }

  /// Enabled recurring transactions whose next run is due on or before [asOf].
  ///
  /// Kept as a plain (non-joined) query — it's read internally by
  /// [RecurringTransactionsRepository.processDueRecurringTransactions],
  /// which only needs the template fields to materialize a transaction,
  /// not the joined Account/Category display objects.
  Future<List<RecurringTransaction>> getDueRecurringTransactions({
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    return (select(recurringTransactions)..where(
          (r) => r.enabled.equals(true) & r.nextRun.isSmallerOrEqualValue(now),
        ))
        .get();
  }

  Future<int> insertRecurringTransaction(
    RecurringTransactionsCompanion entry,
  ) {
    return into(recurringTransactions).insert(entry);
  }

  Future<int> updateRecurringSchedule({
    required int id,
    required TransactionType type,
    required double amount,
    required int accountId,
    int? categoryId,
    int? transferAccountId,
    String? note,
    required RecurringFrequency frequency,
  }) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id))).write(
      RecurringTransactionsCompanion(
        type: Value(type),
        amount: Value(amount),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        transferAccountId: Value(transferAccountId),
        note: Value(note),
        frequency: Value(frequency),
      ),
    );
  }

  Future<int> updateNextRun(int id, DateTime nextRun) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id))).write(
      RecurringTransactionsCompanion(nextRun: Value(nextRun)),
    );
  }

  Future<int> setEnabled(int id, bool enabled) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id))).write(
      RecurringTransactionsCompanion(enabled: Value(enabled)),
    );
  }

  Future<int> deleteRecurringTransaction(int id) {
    return (delete(recurringTransactions)..where((r) => r.id.equals(id))).go();
  }

  Future<int> deleteRecurringTransactionByAccountId(int accountId) {
    return (delete(recurringTransactions)..where(
          (r) =>
              r.accountId.equals(accountId) |
              r.transferAccountId.equals(accountId),
        ))
        .go();
  }
}
