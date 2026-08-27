import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/models/recurring_transaction.dart';
import 'package:money_tracker/core/repositories/transaction_repositories.dart';
import 'package:money_tracker/core/utils/date_math.dart';

class RecurringTransactionsRepository {
  const RecurringTransactionsRepository(
    this._db,
    this._transactionsRepository,
  );

  final AppDatabase _db;
  final TransactionsRepository _transactionsRepository;

  static const int _maxCatchUpIterations = 500;

  Stream<List<RecurringTransactionWithJoin>> watchRecurringTransactions() =>
      _db.recurringTransactionsDao.watchAllRecurringTransactions();

  Stream<List<RecurringTransactionWithJoin>> watchEnabledRecurringTransactions() =>
      _db.recurringTransactionsDao.watchEnabledRecurringTransactions();

  Future<RecurringTransactionWithJoin?> getRecurringTransactionById(int id) =>
      _db.recurringTransactionsDao.getRecurringTransactionById(id);

  /// Creates a recurring schedule directly from template fields — no real
  /// [Transaction] row is created up front. [startDate] is the date of the
  /// first occurrence; `nextRun` is seeded to it, so if it's already due
  /// (today or in the past) the first call to
  /// [processDueRecurringTransactions] will materialize it immediately.
  Future<int> scheduleRecurring({
    required TransactionType type,
    required double amount,
    required int accountId,
    required RecurringFrequency frequency,
    required DateTime startDate,
    int? categoryId,
    int? transferAccountId,
    String? note,
    bool enabled = true,
  }) async {
    if (type != TransactionType.transfer && categoryId == null) {
      throw StateError('$type recurring transactions require a category');
    }
    if (type == TransactionType.transfer && transferAccountId == null) {
      throw StateError('Recurring transfers require a destination account');
    }

    return _db.recurringTransactionsDao.insertRecurringTransaction(
      RecurringTransactionsCompanion.insert(
        type: type,
        amount: amount,
        accountId: accountId,
        frequency: frequency,
        nextRun: startDate,
        categoryId: Value(categoryId),
        transferAccountId: Value(transferAccountId),
        note: Value(note),
        enabled: Value(enabled),
      ),
    );
  }

  /// Edits the template fields of an existing schedule (amount, category,
  /// etc). Does not touch `nextRun` or already-created transactions.
  // RecurringTransactionsRepository — replaces updateRecurringTemplate

  Future<void> updateRecurringSchedule({
    required int id,
    required TransactionType type,
    required double amount,
    required int accountId,
    int? categoryId,
    int? transferAccountId,
    String? note,
    required RecurringFrequency frequency,
  }) async {
    if (type != TransactionType.transfer && categoryId == null) {
      throw StateError('$type recurring transactions require a category');
    }
    if (type == TransactionType.transfer && transferAccountId == null) {
      throw StateError('Recurring transfers require a destination account');
    }

    await _db.recurringTransactionsDao.updateRecurringSchedule(
      id: id,
      type: type,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      transferAccountId: transferAccountId,
      note: note,
      frequency: frequency,
    );
  }

  Future<void> setEnabled(int id, bool enabled) =>
      _db.recurringTransactionsDao.setEnabled(id, enabled);

  Future<void> deleteRecurring(int id) =>
      _db.recurringTransactionsDao.deleteRecurringTransaction(id);

  Future<int> processDueRecurringTransactions({DateTime? asOf}) async {
    final now = asOf ?? DateTime.now();
    final due = await _db.recurringTransactionsDao.getDueRecurringTransactions(
      asOf: now,
    );

    var created = 0;
    for (final recurring in due) {
      created += await _processOne(recurring, now);
    }
    return created;
  }

  Future<int> _processOne(
    RecurringTransaction recurring,
    DateTime now,
  ) async {
    var created = 0;
    var nextRun = recurring.nextRun;
    var iterations = 0;

    while (!nextRun.isAfter(now) && iterations < _maxCatchUpIterations) {
      await _materialize(recurring, nextRun);
      created++;

      nextRun = nextRunAfter(nextRun, recurring.frequency);
      iterations++;
    }

    await _db.recurringTransactionsDao.updateNextRun(recurring.id, nextRun);
    return created;
  }

  Future<void> _materialize(RecurringTransaction recurring, DateTime date) {
    switch (recurring.type) {
      case TransactionType.income:
        return _transactionsRepository.addIncome(
          amount: recurring.amount,
          accountId: recurring.accountId,
          categoryId: recurring.categoryId!,
          note: recurring.note,
          transactionDate: date,
        );

      case TransactionType.expense:
        return _transactionsRepository.addExpense(
          amount: recurring.amount,
          accountId: recurring.accountId,
          categoryId: recurring.categoryId!,
          note: recurring.note,
          transactionDate: date,
        );

      case TransactionType.transfer:
        return _transactionsRepository.addTransfer(
          amount: recurring.amount,
          accountId: recurring.accountId,
          categoryId: recurring.categoryId!,
          note: recurring.note,
          transactionDate: date,
          transferAccountId: recurring.transferAccountId!,
        );
    }
  }

  DateTime nextRunAfter(DateTime date, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return addMonths(date, 1);
      case RecurringFrequency.quarterly:
        return addMonths(date, 3);
      case RecurringFrequency.yearly:
        return addMonths(date, 12);
    }
  }
}
