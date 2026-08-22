import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/providers/database_provider.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/repositories/budgets_repositories.dart';

final allBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  return ref.watch(budgetsRepositoryProvider).watchBudgets();
});

// Stream of all transactions to trigger reactivity when any transaction is created/updated/deleted
final allTransactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.transactions).watch();
});

final allBudgetsProgressProvider = FutureProvider<List<BudgetProgress>>((ref) async {
  // Re-run whenever budgets or transactions change
  ref.watch(allBudgetsProvider);
  ref.watch(allTransactionsStreamProvider);
  
  final budgets = await ref.read(budgetsRepositoryProvider).watchBudgets().first;
  final repo = ref.read(budgetsRepositoryProvider);
  
  final result = <BudgetProgress>[];
  for (final budget in budgets) {
    final progress = await repo.getBudgetProgress(budget.id);
    if (progress != null) {
      result.add(progress);
    }
  }
  return result;
});
