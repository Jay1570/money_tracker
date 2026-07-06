import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/accounts.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/database/tables/transactions.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions, Accounts, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// All transactions, most recent first.
  Stream<List<Transaction>> watchAllTransactions() {
    return (select(
      transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])).watch();
  }

  Future<List<Transaction>> getAllTransactions() {
    return (select(
      transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])).get();
  }

  Stream<Transaction?> watchTransactionById(int id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<Transaction?> getTransactionById(int id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// One-off (non-streamed) fetch of all transactions touching an account,
  /// either as the source account or as the transfer destination.
  Future<List<Transaction>> getTransactionsByAccount(int accountId) {
    return (select(transactions)..where(
          (t) =>
              t.accountId.equals(accountId) |
              t.transferAccountId.equals(accountId),
        ))
        .get();
  }

  Stream<List<Transaction>> watchTransactionsByAccount(int accountId) {
    return (select(transactions)
          ..where(
            (t) =>
                t.accountId.equals(accountId) |
                t.transferAccountId.equals(accountId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  Future<List<Transaction>> getTransactionsByCategory(int categoryId) {
    return (select(
      transactions,
    )..where((t) => t.categoryId.equals(categoryId))).get();
  }

  Stream<List<Transaction>> watchTransactionsByCategory(int categoryId) {
    return (select(transactions)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  Stream<List<Transaction>> watchTransactionsByType(TransactionType type) {
    return (select(transactions)
          ..where((t) => t.type.equalsValue(type))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  Stream<List<Transaction>> watchTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where(
            (t) =>
                t.transactionDate.isBiggerOrEqualValue(start) &
                t.transactionDate.isSmallerOrEqualValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  /// Recent transactions, limited by [limit].
  Stream<List<Transaction>> watchRecentTransactions({int limit = 10}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .watch();
  }

  /// Sum of amounts for a given type within an optional date range.
  Stream<double> watchTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  }) {
    final totalExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([totalExp])
      ..where(transactions.type.equalsValue(type));

    if (start != null) {
      query.where(transactions.transactionDate.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(transactions.transactionDate.isSmallerOrEqualValue(end));
    }

    return query.map((row) => row.read(totalExp) ?? 0).watchSingle();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) {
    return update(transactions).replace(entry);
  }

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
