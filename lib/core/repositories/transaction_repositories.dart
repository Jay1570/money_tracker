import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class TransactionsRepository {
  const TransactionsRepository(this._db);

  final AppDatabase _db;

  Future<int> addExpense({
    required double amount,
    required int accountId,
    required int categoryId,
    String? note,
    required DateTime transactionDate,
  }) async {
    return _addTransaction(
      type: TransactionType.expense,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
    );
  }

  Future<int> addIncome({
    required double amount,
    required int accountId,
    required int categoryId,
    String? note,
    required DateTime transactionDate,
  }) async {
    return _addTransaction(
      type: TransactionType.income,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
    );
  }

  Future<int> transfer({
    required double amount,
    required int accountId,
    required int categoryId,
    String? note,
    required DateTime transactionDate,
    required int transferAccountId,
  }) async {
    return _addTransaction(
      type: TransactionType.transfer,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
      transferAccountId: transferAccountId,
    );
  }

  Future<void> updateIncome({
    required int transactionId,
    required double amount,
    required int accountId,
    required int categoryId,
    String? note,
    required DateTime transactionDate,
  }) {
    return _updateTransaction(
      id: transactionId,
      type: TransactionType.income,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
    );
  }

  Future<void> updateExpense({
    required int transactionId,
    required double amount,
    required int accountId,
    required int categoryId,
    String? note,
    required DateTime transactionDate,
  }) {
    return _updateTransaction(
      id: transactionId,
      type: TransactionType.expense,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
    );
  }

  Future<void> updateTransfer({
    required int transactionId,
    required double amount,
    required int accountId,
    required int categoryId,
    String? note,
    required DateTime transactionDate,
    required int transferAccountId,
  }) {
    return _updateTransaction(
      id: transactionId,
      type: TransactionType.transfer,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
      transferAccountId: transferAccountId,
    );
  }

  /// Deletes a transaction, reverses its effect on account balance(s),
  /// and cleans up any dependent rows (tag links, recurring schedule)
  /// that reference it.
  Future<void> deleteTransaction(int transactionId) async {
    await _db.transaction(() async {
      final existing = await _db.transactionsDao.getTransactionById(
        transactionId,
      );
      if (existing == null) return;

      await _reverseBalanceEffect(existing);

      await _db.transactionTagsDao.clearTagsForTransaction(transactionId);

      final recurring = await _db.recurringTransactionsDao
          .getRecurringTransactionByTransactionId(transactionId);
      if (recurring != null) {
        await _db.recurringTransactionsDao.deleteRecurringTransaction(
          recurring.id,
        );
      }

      await _db.transactionsDao.deleteTransaction(transactionId);
    });
  }

  Future<int> _addTransaction({
    required TransactionType type,
    required double amount,
    required int accountId,
    required int? categoryId,
    String? note,
    required DateTime transactionDate,
    int? transferAccountId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }

    _assertTransferAccount(type, accountId, transferAccountId);

    return _db.transaction(() async {
      final id = await _db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: amount,
          type: type,
          accountId: accountId,
          categoryId: Value(categoryId),
          transferAccountId: Value(transferAccountId),
          note: Value(note),
          transactionDate: transactionDate,
        ),
      );

      await _applyBalanceEffect(
        type: type,
        amount: amount,
        accountId: accountId,
        transferAccountId: transferAccountId,
      );

      return id;
    });
  }

  Future<void> _updateTransaction({
    required int id,
    required TransactionType type,
    required double amount,
    required int accountId,
    required int? categoryId,
    String? note,
    required DateTime transactionDate,
    int? transferAccountId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
    
    _assertTransferAccount(type, accountId, transferAccountId);

    await _db.transaction(() async {
      final existing = await _db.transactionsDao.getTransactionById(id);
      if (existing == null) {
        throw StateError('Transaction $id not found');
      }

      // Undo the balance effect of the transaction as it currently is,
      // before applying the new values.
      await _reverseBalanceEffect(existing);

      await _db.transactionsDao.updateTransaction(
        TransactionsCompanion(
          id: Value(id),
          amount: Value(amount),
          type: Value(type),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
          transferAccountId: Value(transferAccountId),
          note: Value(note),
          transactionDate: Value(transactionDate),
        ),
      );

      await _applyBalanceEffect(
        type: type,
        amount: amount,
        accountId: accountId,
        transferAccountId: transferAccountId,
      );
    });
  }

  /// Applies the balance impact of a transaction to the relevant account(s).
  Future<void> _applyBalanceEffect({
    required TransactionType type,
    required double amount,
    required int accountId,
    int? transferAccountId,
  }) async {
    switch (type) {
      case TransactionType.income:
        await _db.accountsDao.adjustBalance(accountId, amount);
        break;

      case TransactionType.expense:
        await _db.accountsDao.adjustBalance(accountId, -amount);
        break;

      case TransactionType.transfer:
        await _db.accountsDao.adjustBalance(accountId, -amount);
        await _db.accountsDao.adjustBalance(transferAccountId!, amount);
        break;
    }
  }

  /// Reverses the balance impact a transaction previously had, by applying
  /// the same effect with the amount's sign flipped.
  Future<void> _reverseBalanceEffect(Transaction tx) {
    return _applyBalanceEffect(
      type: tx.type,
      amount: -tx.amount,
      accountId: tx.accountId,
      transferAccountId: tx.transferAccountId,
    );
  }

  void _assertTransferAccount(TransactionType type, int accountId, int? transferAccountId) {
    if (type == TransactionType.transfer && transferAccountId == null) {
      throw ArgumentError(
        'transferAccountId is required for transfer transactions',
      );
    }

    if (type == TransactionType.transfer && transferAccountId == accountId) {
      throw ArgumentError(
        'Source and destination accounts cannot be the same.',
      );
    }
  }
}
