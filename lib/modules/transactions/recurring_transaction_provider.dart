import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/models/recurring_transaction.dart';
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

final recurringTransactionDetailsProvider =
    FutureProvider.family<RecurringTransactionWithJoin?, int>((
      ref,
      transactionId,
    ) {
      return ref
          .watch(recurringTransactionsRepositoryProvider)
          .getRecurringTransactionById(transactionId);
    });
