import 'package:money_tracker/core/repositories/budgets_repositories.dart';
import 'package:money_tracker/core/repositories/recurring_transaction_repositories.dart';
import 'package:money_tracker/core/repositories/transaction_repositories.dart';

class AppStartupService {
  AppStartupService(
    this._transactionsRepository,
    this._recurringRepository,
    this._budgetsRepository,
  );

  final TransactionsRepository _transactionsRepository;
  final RecurringTransactionsRepository _recurringRepository;
  final BudgetsRepository _budgetsRepository;

  Future<void> initialize() async {
    await _transactionsRepository.recalculateAllBalances();
    await _recurringRepository.processDueRecurringTransactions();
    await _budgetsRepository.renewExpiredBudgets();
  }
}
