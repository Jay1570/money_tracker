import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';

final recurringTransactionsListProvider =
    StreamProvider<List<RecurringTransaction>>((ref) {
      return ref
          .watch(recurringTransactionsRepositoryProvider)
          .watchRecurringTransactions();
    });

/// A recurring schedule's template transaction, resolved together with its
/// account(s) and category for display. `RecurringTransactions` only
/// stores `transactionId`/`frequency`/`nextRun`/`enabled` — everything
/// else (amount, type, which accounts) lives on the template transaction
/// it points at.
class RecurringTransactionDetails {
  const RecurringTransactionDetails({
    required this.transaction,
    required this.account,
    this.transferAccount,
    this.category,
  });

  final Transaction transaction;
  final Account account;
  final Account? transferAccount;
  final Category? category;
}

final recurringTransactionDetailsProvider =
    FutureProvider.family<RecurringTransactionDetails?, int>((
      ref,
      transactionId,
    ) async {
      final transaction = await ref
          .watch(transactionsRepositoryProvider)
          .getTransactionById(transactionId);
      if (transaction == null) return null;

      final account = await ref
          .watch(accountsRepositoryProvider)
          .getAccount(transaction.accountId);
      if (account == null) return null;

      Account? transferAccount;
      if (transaction.transferAccountId != null) {
        transferAccount = await ref
            .watch(accountsRepositoryProvider)
            .getAccount(transaction.transferAccountId!);
      }

      Category? category;
      if (transaction.categoryId != null) {
        category = await ref
            .watch(categoriesRepositoryProvider)
            .getCategory(transaction.categoryId!);
      }

      return RecurringTransactionDetails(
        transaction: transaction,
        account: account,
        transferAccount: transferAccount,
        category: category,
      );
    });
