import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/database_provider.dart';

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }
}

final monthRangeProvider = Provider<({DateTime start, DateTime end})>((ref) {
  final month = ref.watch(selectedMonthProvider);

  final start = DateTime(month.year, month.month, 1);

  final end = DateTime(
    month.month == 12 ? month.year + 1 : month.year,
    month.month == 12 ? 1 : month.month + 1,
    1,
  );

  return (start: start, end: end);
});

final monthlyTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      final db = ref.watch(databaseProvider);
      final range = ref.watch(monthRangeProvider);

      return db.transactionsDao.watchTransactionsInRange(
        range.start,
        range.end,
      );
    });

final monthlyExpenseProvider = StreamProvider.autoDispose<double>((ref) {
  final db = ref.watch(databaseProvider);
  final range = ref.watch(monthRangeProvider);

  return db.transactionsDao.watchTotalByType(
    TransactionType.expense,
    start: range.start,
    end: range.end,
  );
});

final monthlyIncomeProvider = StreamProvider.autoDispose<double>((ref) {
  final db = ref.watch(databaseProvider);
  final range = ref.watch(monthRangeProvider);

  return db.transactionsDao.watchTotalByType(
    TransactionType.income,
    start: range.start,
    end: range.end,
  );
});

final monthlyBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeProvider).value ?? 0;
  final expense = ref.watch(monthlyExpenseProvider).value ?? 0;

  return income - expense;
});
