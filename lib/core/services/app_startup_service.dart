import 'package:money_tracker/core/repositories/recurring_transaction_repositories.dart';
import 'package:money_tracker/core/repositories/transaction_repositories.dart';

class AppStartupService {
  AppStartupService(
    this._transactionsRepository,
    this._recurringRepository,
  );

  final TransactionsRepository _transactionsRepository;
  final RecurringTransactionsRepository _recurringRepository;

  Future<void> initialize() async {
    await _transactionsRepository.recalculateAllBalances();
    await _recurringRepository.processDueRecurringTransactions();
  }
}
