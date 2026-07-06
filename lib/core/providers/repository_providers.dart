import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/providers/database_provider.dart';
import 'package:money_tracker/core/repositories/accounts_repository.dart';
import 'package:money_tracker/core/repositories/budgets_repositories.dart';
import 'package:money_tracker/core/repositories/categories_repositories.dart';
import 'package:money_tracker/core/repositories/recurring_transaction_repositories.dart';
import 'package:money_tracker/core/repositories/settings_repository.dart';
import 'package:money_tracker/core/repositories/tags_repositories.dart';
import 'package:money_tracker/core/repositories/transaction_repositories.dart';
import 'package:money_tracker/core/services/app_startup_service.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(databaseProvider));
});

final recurringTransactionsRepositoryProvider =
    Provider<RecurringTransactionsRepository>((ref) {
      return RecurringTransactionsRepository(
        ref.watch(databaseProvider),
        ref.watch(transactionsRepositoryProvider),
      );
    });

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(ref.watch(databaseProvider));
});

final tagsRepositoryProvider = Provider<TagsRepository>((ref) {
  return TagsRepository(ref.watch(databaseProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider));
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final appStartupServiceProvider = Provider<AppStartupService>((ref) {
  return AppStartupService(
    ref.watch(transactionsRepositoryProvider),
    ref.watch(recurringTransactionsRepositoryProvider),
  );
});
