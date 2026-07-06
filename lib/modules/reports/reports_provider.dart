import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/repositories/budgets_repositories.dart';

enum ReportsTab { analytics, accounts }

final reportsTabProvider = StateProvider<ReportsTab>(
  (ref) => ReportsTab.analytics,
);

// --- Analytics tab -------------------------------------------------------

DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);
DateTime _monthEnd(DateTime d) =>
    DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);

final _currentMonthRangeProvider = Provider<({DateTime start, DateTime end})>(
  (ref) {
    final now = DateTime.now();
    return (start: _monthStart(now), end: _monthEnd(now));
  },
);

final reportsMonthlyIncomeProvider = StreamProvider<double>((ref) {
  final range = ref.watch(_currentMonthRangeProvider);
  return ref
      .watch(transactionsRepositoryProvider)
      .watchTotalByType(
        TransactionType.income,
        start: range.start,
        end: range.end,
      );
});

final reportsMonthlyExpenseProvider = StreamProvider<double>((ref) {
  final range = ref.watch(_currentMonthRangeProvider);
  return ref
      .watch(transactionsRepositoryProvider)
      .watchTotalByType(
        TransactionType.expense,
        start: range.start,
        end: range.end,
      );
});

final reportsMonthlyBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(reportsMonthlyIncomeProvider).value ?? 0;
  final expense = ref.watch(reportsMonthlyExpenseProvider).value ?? 0;
  return income - expense;
});

/// Every currently-active budget collapsed into one combined figure, for
/// the single "Monthly Budget" progress ring on the Analytics tab.
class AggregatedBudgetProgress {
  const AggregatedBudgetProgress({required this.budget, required this.spent});

  final double budget;
  final double spent;

  double get remaining => budget - spent;

  double get percentRemaining =>
      budget <= 0 ? 0 : (remaining / budget).clamp(0, 1);
}

final activeBudgetsProgressProvider = FutureProvider<List<BudgetProgress>>((
  ref,
) {
  return ref.watch(budgetsRepositoryProvider).getActiveBudgetsProgress();
});

final aggregatedBudgetProvider = Provider<AggregatedBudgetProgress?>((ref) {
  final list = ref.watch(activeBudgetsProgressProvider).value;
  if (list == null || list.isEmpty) return null;

  final totalBudget = list.fold<double>(0, (sum, b) => sum + b.budget.amount);
  final totalSpent = list.fold<double>(0, (sum, b) => sum + b.spent);
  return AggregatedBudgetProgress(budget: totalBudget, spent: totalSpent);
});

// --- Accounts tab ----------------------------------------------------------

final accountsListProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAccounts();
});

final netWorthProvider = StreamProvider<double>((ref) {
  return ref.watch(accountsRepositoryProvider).watchNetWorth();
});

/// Derived from the account list using [AccountTypeX.isLiability] — a
/// credit card or loan's balance is what's owed (a liability), regardless
/// of sign; everything else is an asset.
final assetsAndLiabilitiesProvider =
    Provider<({double assets, double liabilities})>((ref) {
      final accounts = ref.watch(accountsListProvider).value ?? const [];
      var assets = 0.0;
      var liabilities = 0.0;
      for (final account in accounts) {
        if (account.type.isLiability) {
          liabilities += account.currentBalance.abs();
        } else {
          assets += account.currentBalance;
        }
      }
      return (assets: assets, liabilities: liabilities);
    });

/// Accounts grouped by [AccountType], in enum declaration order, with
/// empty groups omitted.
final groupedAccountsProvider = Provider<Map<AccountType, List<Account>>>((
  ref,
) {
  final accounts = ref.watch(accountsListProvider).value ?? const [];
  final map = <AccountType, List<Account>>{};
  for (final type in AccountType.values) {
    final matching = accounts.where((a) => a.type == type).toList();
    if (matching.isNotEmpty) map[type] = matching;
  }
  return map;
});

/// The app's currently configured currency code (e.g. "INR"), defaulting
/// to "INR" until settings finish loading.
final currencyCodeProvider = FutureProvider<String>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).getSettings();
  return settings.currency;
});
