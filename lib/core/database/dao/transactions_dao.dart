import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/accounts.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/database/tables/transactions.dart';
import 'package:money_tracker/core/models/transaction.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions, Accounts, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// All transactions, most recent first.
  Stream<List<TransactionWithJoin>> watchAllTransactions() {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      innerJoin(
        sourceAccount,
        sourceAccount.id.equalsExp(transactions.accountId),
      ),
      leftOuterJoin(
        transferAccountTable,
        transferAccountTable.id.equalsExp(transactions.transferAccountId),
      ),
    ])..orderBy([OrderingTerm.desc(transactions.transactionDate)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Future<List<TransactionWithJoin>> getAllTransactions() {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      innerJoin(
        sourceAccount,
        sourceAccount.id.equalsExp(transactions.accountId),
      ),
      leftOuterJoin(
        transferAccountTable,
        transferAccountTable.id.equalsExp(transactions.transferAccountId),
      ),
    ])..orderBy([OrderingTerm.desc(transactions.transactionDate)]);

    return query.get().then(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Stream<TransactionWithJoin?> watchTransactionById(int id) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      innerJoin(
        sourceAccount,
        sourceAccount.id.equalsExp(transactions.accountId),
      ),
      leftOuterJoin(
        transferAccountTable,
        transferAccountTable.id.equalsExp(transactions.transferAccountId),
      ),
    ])..where(transactions.id.equals(id));

    return query.watchSingleOrNull().map(
      (row) => row == null
          ? null
          : _mapRow(row, sourceAccount, transferAccountTable),
    );
  }

  Future<TransactionWithJoin?> getTransactionById(int id) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      innerJoin(
        sourceAccount,
        sourceAccount.id.equalsExp(transactions.accountId),
      ),
      leftOuterJoin(
        transferAccountTable,
        transferAccountTable.id.equalsExp(transactions.transferAccountId),
      ),
    ])..where(transactions.id.equals(id));

    return query.getSingleOrNull().then(
      (row) => row == null
          ? null
          : _mapRow(row, sourceAccount, transferAccountTable),
    );
  }

  /// One-off (non-streamed) fetch of all transactions touching an account,
  /// either as the source account or as the transfer destination.
  Future<List<TransactionWithJoin>> getTransactionsByAccount(int accountId) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
          leftOuterJoin(
            categories,
            categories.id.equalsExp(transactions.categoryId),
          ),
          innerJoin(
            sourceAccount,
            sourceAccount.id.equalsExp(transactions.accountId),
          ),
          leftOuterJoin(
            transferAccountTable,
            transferAccountTable.id.equalsExp(transactions.transferAccountId),
          ),
        ])..where(
          transactions.accountId.equals(accountId) |
              transactions.transferAccountId.equals(accountId),
        );

    return query.get().then(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Stream<List<TransactionWithJoin>> watchTransactionsByAccount(int accountId) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            innerJoin(
              sourceAccount,
              sourceAccount.id.equalsExp(transactions.accountId),
            ),
            leftOuterJoin(
              transferAccountTable,
              transferAccountTable.id.equalsExp(transactions.transferAccountId),
            ),
          ])
          ..where(
            transactions.accountId.equals(accountId) |
                transactions.transferAccountId.equals(accountId),
          )
          ..orderBy([OrderingTerm.desc(transactions.transactionDate)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Future<List<TransactionWithJoin>> getTransactionsByCategory(int categoryId) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      innerJoin(
        sourceAccount,
        sourceAccount.id.equalsExp(transactions.accountId),
      ),
      leftOuterJoin(
        transferAccountTable,
        transferAccountTable.id.equalsExp(transactions.transferAccountId),
      ),
    ])..where(transactions.categoryId.equals(categoryId));

    return query.get().then(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Future<List<TransactionWithJoin>> getTransactionsByCategoryInRange(
    int categoryId, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
          leftOuterJoin(
            categories,
            categories.id.equalsExp(transactions.categoryId),
          ),
          innerJoin(
            sourceAccount,
            sourceAccount.id.equalsExp(transactions.accountId),
          ),
          leftOuterJoin(
            transferAccountTable,
            transferAccountTable.id.equalsExp(transactions.transferAccountId),
          ),
        ])..where(
          transactions.categoryId.equals(categoryId) &
              (transactions.transactionDate.isBiggerOrEqualValue(startDate) &
                  transactions.transactionDate.isSmallerOrEqualValue(endDate)),
        );

    return query.get().then(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Stream<List<TransactionWithJoin>> watchTransactionsByCategory(
    int categoryId,
  ) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            innerJoin(
              sourceAccount,
              sourceAccount.id.equalsExp(transactions.accountId),
            ),
            leftOuterJoin(
              transferAccountTable,
              transferAccountTable.id.equalsExp(transactions.transferAccountId),
            ),
          ])
          ..where(transactions.categoryId.equals(categoryId))
          ..orderBy([OrderingTerm.desc(transactions.transactionDate)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Stream<List<TransactionWithJoin>> watchTransactionsByType(
    TransactionType type,
  ) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            innerJoin(
              sourceAccount,
              sourceAccount.id.equalsExp(transactions.accountId),
            ),
            leftOuterJoin(
              transferAccountTable,
              transferAccountTable.id.equalsExp(transactions.transferAccountId),
            ),
          ])
          ..where(transactions.type.equalsValue(type))
          ..orderBy([OrderingTerm.desc(transactions.transactionDate)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  Future<List<TransactionWithJoin>> getTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccount = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            innerJoin(
              sourceAccount,
              sourceAccount.id.equalsExp(transactions.accountId),
            ),
            leftOuterJoin(
              transferAccount,
              transferAccount.id.equalsExp(transactions.transferAccountId),
            ),
          ])
          ..where(
            transactions.transactionDate.isBiggerOrEqualValue(start) &
                transactions.transactionDate.isSmallerOrEqualValue(end),
          )
          ..orderBy([OrderingTerm.desc(transactions.transactionDate)]);

    return query.get().then(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccount))
          .toList(),
    );
  }

  Stream<List<TransactionWithJoin>> watchTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccount = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            innerJoin(
              sourceAccount,
              sourceAccount.id.equalsExp(transactions.accountId),
            ),
            leftOuterJoin(
              transferAccount,
              transferAccount.id.equalsExp(transactions.transferAccountId),
            ),
          ])
          ..where(
            transactions.transactionDate.isBiggerOrEqualValue(start) &
                transactions.transactionDate.isSmallerOrEqualValue(end),
          )
          ..orderBy([OrderingTerm.desc(transactions.transactionDate)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccount))
          .toList(),
    );
  }

  /// Recent transactions, limited by [limit].
  Stream<List<TransactionWithJoin>> watchRecentTransactions({int limit = 10}) {
    final sourceAccount = alias(accounts, 'sourceAccount');
    final transferAccountTable = alias(accounts, 'transferAccount');

    final query =
        select(transactions).join([
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            innerJoin(
              sourceAccount,
              sourceAccount.id.equalsExp(transactions.accountId),
            ),
            leftOuterJoin(
              transferAccountTable,
              transferAccountTable.id.equalsExp(transactions.transferAccountId),
            ),
          ])
          ..orderBy([OrderingTerm.desc(transactions.transactionDate)])
          ..limit(limit);

    return query.watch().map(
      (rows) => rows
          .map((row) => _mapRow(row, sourceAccount, transferAccountTable))
          .toList(),
    );
  }

  /// Sum of amounts for a given type within an optional date range.
  /// Aggregate-only — no join needed here since no row data is returned.
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

  TransactionWithJoin _mapRow(
    TypedResult row,
    $AccountsTable sourceAccount,
    $AccountsTable transferAccountTable,
  ) {
    final t = row.readTable(transactions);

    return TransactionWithJoin(
      id: t.id,
      amount: t.amount,
      type: t.type,
      accountId: t.accountId,
      categoryId: t.categoryId,
      transferAccountId: t.transferAccountId,
      note: t.note,
      transactionDate: t.transactionDate,
      createdAt: t.createdAt,
      account: row.readTable(sourceAccount),
      transferAccount: row.readTableOrNull(transferAccountTable),
      category: row.readTableOrNull(categories),
    );
  }
}
