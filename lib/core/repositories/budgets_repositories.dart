import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/models/transaction.dart';
import 'package:money_tracker/core/utils/date_math.dart';

/// A budget combined with how much has actually been spent against it.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
  });

  final Budget budget;
  final double spent;

  double get remaining => budget.amount - spent;

  /// 0.0–1.0+ (can exceed 1.0 when over budget).
  double get percentUsed => budget.amount <= 0
      ? 0
      : (spent / budget.amount).clamp(0, double.infinity);

  bool get isOverBudget => spent > budget.amount;
}

class BudgetsRepository {
  const BudgetsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Budget>> watchBudgets() => _db.budgetsDao.watchAllBudgets();

  Stream<List<Budget>> watchActiveBudgets({DateTime? asOf}) =>
      _db.budgetsDao.watchActiveBudgets(asOf: asOf);

  Future<List<int>> renewExpiredBudgets({DateTime? asOf}) async {
    final now = asOf ?? DateTime.now();
    final all = await _db.budgetsDao.getAllBudgets();

    final expired = all.where((b) => b.endDate.isBefore(now));

    final newIds = <int>[];
    for (final budget in expired) {
      // Skip if a renewal already exists (same category+period starting
      // right after this one ended) to avoid duplicate chains if this
      // ever runs twice before the stream refreshes.
      final alreadyRenewed = all.any(
        (b) =>
            b.categoryId == budget.categoryId &&
            b.period == budget.period &&
            b.startDate.isAtSameMomentAs(
              budget.endDate.add(const Duration(days: 1)),
            ),
      );
      if (alreadyRenewed) continue;

      final newId = await renewBudget(budget.id);
      newIds.add(newId);
    }

    return newIds;
  }

  Future<int> renewBudget(
    int budgetId, {
    double? amount,
    BudgetPeriod? period,
  }) async {
    final budget = await _db.budgetsDao.getBudgetById(budgetId);
    if (budget == null) {
      throw StateError('Budget $budgetId does not exist');
    }

    final newStartDate = budget.endDate.add(const Duration(days: 1));

    return createBudget(
      categoryId: budget.categoryId,
      amount: amount ?? budget.amount,
      period: period ?? budget.period,
      startDate: newStartDate,
    );
  }

  /// Creates a budget. Only expense categories can be budgeted — income
  /// doesn't get "budgeted" in the usual sense. If [endDate] is omitted,
  /// it's derived automatically from [period] and [startDate].
  Future<int> createBudget({
    required int? categoryId,
    required double amount,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Budget amount must be greater than zero');
    }

    if (categoryId != null) {
      final category = await _db.categoriesDao.getCategoryById(categoryId);
      if (category == null) {
        throw StateError('Category $categoryId does not exist');
      }
      if (category.type != CategoryType.expense) {
        throw ArgumentError(
          'Budgets can only be created for expense categories',
        );
      }
    }

    final resolvedEndDate = endDate ?? endDateForPeriod(startDate, period);
    if (!resolvedEndDate.isAfter(startDate)) {
      throw ArgumentError('endDate must be after startDate');
    }

    return _db.budgetsDao.insertBudget(
      BudgetsCompanion.insert(
        categoryId: Value(categoryId),
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: resolvedEndDate,
      ),
    );
  }

  Future<void> updateBudget({
    required int id,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (amount != null && amount <= 0) {
      throw ArgumentError('Budget amount must be greater than zero');
    }
    if (startDate != null && endDate != null && !endDate.isAfter(startDate)) {
      throw ArgumentError('endDate must be after startDate');
    }

    await _db.budgetsDao.updateBudget(
      BudgetsCompanion(
        id: Value(id),
        amount: amount != null ? Value(amount) : const Value.absent(),
        period: period != null ? Value(period) : const Value.absent(),
        startDate: startDate != null ? Value(startDate) : const Value.absent(),
        endDate: endDate != null ? Value(endDate) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteBudget(int id) => _db.budgetsDao.deleteBudget(id);

  /// Computes actual spend for a single budget by summing expense
  /// transactions in its category that fall within its date range.
  Future<BudgetProgress?> getBudgetProgress(int budgetId) async {
    final budget = await _db.budgetsDao.getBudgetById(budgetId);
    if (budget == null) return null;
    return _progressFor(budget);
  }

  /// Progress for every currently-active budget.
  Future<List<BudgetProgress>> getActiveBudgetsProgress({
    DateTime? asOf,
  }) async {
    final now = asOf ?? DateTime.now();
    final all = await _db.budgetsDao.getAllBudgets();
    final active = all.where(
      (b) => b.startDate.isBefore(now) && b.endDate.isAfter(now),
    );

    final result = <BudgetProgress>[];
    for (final budget in active) {
      result.add(await _progressFor(budget));
    }
    return result;
  }

  Future<BudgetProgress> _progressFor(Budget budget) async {
    List<TransactionWithJoin> transactions = [];

    if (budget.categoryId != null) {
      transactions = await _db.transactionsDao.getTransactionsByCategoryInRange(
        budget.categoryId!,
        startDate: budget.startDate,
        endDate: budget.endDate,
      );
    } else {
      transactions = await _db.transactionsDao.getTransactionsInRange(
        budget.startDate,
        budget.endDate,
      );
    }

    final spent = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              !tx.transactionDate.isBefore(budget.startDate) &&
              !tx.transactionDate.isAfter(budget.endDate),
        )
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return BudgetProgress(budget: budget, spent: spent);
  }

  /// Computes an end date for a budget period, anchored to [startDate].
  /// Month/year arithmetic clips the day-of-month instead of overflowing
  /// (e.g. Jan 31 + 1 month lands on the last day of February, not March 3).
  static DateTime endDateForPeriod(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return addMonths(startDate, 1);
      case BudgetPeriod.yearly:
        return addMonths(startDate, 12);
    }
  }
}
