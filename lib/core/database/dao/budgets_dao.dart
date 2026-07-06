import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/budgets.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets, Categories])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  Future<List<Budget>> getAllBudgets() {
    return select(budgets).get();
  }

  Stream<List<Budget>> watchAllBudgets() {
    return select(budgets).watch();
  }

  Stream<Budget?> watchBudgetById(int id) {
    return (select(budgets)..where((b) => b.id.equals(id))).watchSingleOrNull();
  }

  Future<Budget?> getBudgetById(int id) {
    return (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<List<Budget>> getBudgetsByCategory(int categoryId) {
    return (select(
      budgets,
    )..where((b) => b.categoryId.equals(categoryId))).get();
  }

  Stream<List<Budget>> watchBudgetsByCategory(int categoryId) {
    return (select(
      budgets,
    )..where((b) => b.categoryId.equals(categoryId))).watch();
  }

  Stream<List<Budget>> watchBudgetsByPeriod(BudgetPeriod period) {
    return (select(
      budgets,
    )..where((b) => b.period.equalsValue(period))).watch();
  }

  /// Budgets that are active (today falls within their start/end range).
  Stream<List<Budget>> watchActiveBudgets({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    return (select(budgets)..where(
          (b) =>
              b.startDate.isSmallerOrEqualValue(now) &
              b.endDate.isBiggerOrEqualValue(now),
        ))
        .watch();
  }

  Future<int> insertBudget(BudgetsCompanion entry) {
    return into(budgets).insert(entry);
  }

  Future<bool> updateBudget(BudgetsCompanion entry) {
    return update(budgets).replace(entry);
  }

  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }
}
