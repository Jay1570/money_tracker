import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/repositories/transaction_repositories.dart';
import 'package:money_tracker/core/utils/date_math.dart';

class RecurringTransactionsRepository {
  const RecurringTransactionsRepository(
    this._db,
    this._transactionsRepository,
  );

  final AppDatabase _db;
  final TransactionsRepository _transactionsRepository;

  /// A safety cap on how many missed occurrences a single recurring
  /// transaction will be allowed to catch up on in one call. Prevents a
  /// runaway loop if, say, a `nextRun` from years ago slipped through.
  static const int _maxCatchUpIterations = 500;

  Stream<List<RecurringTransaction>> watchRecurringTransactions() =>
      _db.recurringTransactionsDao.watchAllRecurringTransactions();

  Stream<List<RecurringTransaction>> watchEnabledRecurringTransactions() =>
      _db.recurringTransactionsDao.watchEnabledRecurringTransactions();

  /// Schedules an existing transaction as the template for a recurring
  /// series. There can only be one recurring schedule per template
  /// transaction.
  Future<int> scheduleRecurring({
    required int templateTransactionId,
    required RecurringFrequency frequency,
    required DateTime nextRun,
    bool enabled = true,
  }) async {
    final template = await _db.transactionsDao.getTransactionById(
      templateTransactionId,
    );
    if (template == null) {
      throw StateError('Transaction $templateTransactionId does not exist');
    }

    final existing = await _db.recurringTransactionsDao
        .getRecurringTransactionByTransactionId(templateTransactionId);
    if (existing != null) {
      throw StateError(
        'Transaction $templateTransactionId already has a recurring '
        'schedule (id ${existing.id})',
      );
    }

    return _db.recurringTransactionsDao.insertRecurringTransaction(
      RecurringTransactionsCompanion.insert(
        transactionId: templateTransactionId,
        frequency: frequency,
        nextRun: nextRun,
        enabled: Value(enabled),
      ),
    );
  }

  Future<void> setEnabled(int id, bool enabled) =>
      _db.recurringTransactionsDao.setEnabled(id, enabled);

  Future<void> deleteRecurring(int id) =>
      _db.recurringTransactionsDao.deleteRecurringTransaction(id);

  /// The core scheduling job: finds every enabled recurring transaction
  /// whose `nextRun` has arrived, materializes a real transaction (via
  /// [TransactionsRepository], so account balances stay correct) for each
  /// missed occurrence up to [asOf], and advances `nextRun` past it.
  ///
  /// Safe to call repeatedly (e.g. on every app launch, or from a
  /// background job) — occurrences that aren't due yet are simply left
  /// alone.
  ///
  /// Returns the number of transactions created.
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
      final template = await _db.transactionsDao.getTransactionById(
        recurring.transactionId,
      );
      if (template == null) {
        // The template transaction was deleted out from under this
        // schedule — disable it rather than looping on a dangling
        // reference forever.
        await _db.recurringTransactionsDao.setEnabled(recurring.id, false);
        break;
      }

      await _cloneTransaction(template, nextRun);
      created++;

      nextRun = nextRunAfter(nextRun, recurring.frequency);
      iterations++;
    }

    await _db.recurringTransactionsDao.updateNextRun(recurring.id, nextRun);
    return created;
  }

  Future<void> _cloneTransaction(Transaction template, DateTime date) {
    final categoryId = template.categoryId;
    if (categoryId == null) {
      throw StateError(
        'Recurring template transaction ${template.id} has no category and '
        'cannot be cloned',
      );
    }

    switch (template.type) {
      case TransactionType.income:
        return _transactionsRepository.addIncome(
          amount: template.amount,
          accountId: template.accountId,
          categoryId: categoryId,
          note: template.note,
          transactionDate: date,
        );

      case TransactionType.expense:
        return _transactionsRepository.addExpense(
          amount: template.amount,
          accountId: template.accountId,
          categoryId: categoryId,
          note: template.note,
          transactionDate: date,
        );

      case TransactionType.transfer:
        final transferAccountId = template.transferAccountId;
        if (transferAccountId == null) {
          throw StateError(
            'Recurring transfer template ${template.id} has no destination '
            'account and cannot be cloned',
          );
        }
        return _transactionsRepository.addTransfer(
          amount: template.amount,
          accountId: template.accountId,
          categoryId: categoryId,
          note: template.note,
          transactionDate: date,
          transferAccountId: transferAccountId,
        );
    }
  }

  /// The next occurrence date after [date] for a given [frequency].
  /// Public so callers (e.g. the Add Transaction screen) can compute the
  /// initial `nextRun` when scheduling a new recurring series — the first
  /// occurrence is the transaction itself, so the schedule's `nextRun`
  /// should start one period after its date, not on it.
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
