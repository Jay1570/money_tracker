import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/utils/currency_format.dart';
import 'package:money_tracker/modules/reports/reports_provider.dart'
    show currencyCodeProvider;
import 'package:money_tracker/modules/transactions/recurring_transaction_provider.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionsListProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xff171717),
      appBar: AppBar(
        backgroundColor: colors.surfaceContainer,
        elevation: 0,
        title: const Text(
          'Recurring Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: recurringAsync.when(
          data: (items) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'No recurring transactions yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  for (final recurring in items) ...[
                    _RecurringTile(recurring: recurring),
                    const Divider(color: Colors.white12, height: 1),
                  ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/recurring-transactions/add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  const _RecurringTile({required this.recurring});

  final RecurringTransaction recurring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(
      recurringTransactionDetailsProvider(recurring.transactionId),
    );
    final currency = ref.watch(currencyCodeProvider).value ?? 'INR';

    return detailsAsync.when(
      data: (details) {
        if (details == null) {
          // The template transaction was deleted out from under this
          // schedule but the schedule row itself wasn't cleaned up —
          // shouldn't normally happen since deleteTransaction guards
          // against this, but shown defensively just in case.
          return const SizedBox.shrink();
        }

        final isTransfer = details.type == TransactionType.transfer;
        final title = isTransfer
            ? '${details.account.name} -> ${details.transferAccount!.name}'
            : (details.category?.name ?? details.account.name);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _frequencyLabel(recurring.frequency),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              if (isTransfer)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency ${formatAmount(details.amount)}',
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$currency ${formatAmount(details.amount)}',
                        ),
                      ],
                    ),
                  ],
                )
              else
                Text(
                  formatAmount(details.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: LinearProgressIndicator(minHeight: 1),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(e.toString(), style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

String _frequencyLabel(RecurringFrequency frequency) {
  switch (frequency) {
    case RecurringFrequency.daily:
      return 'Daily';
    case RecurringFrequency.weekly:
      return 'Weekly';
    case RecurringFrequency.monthly:
      return 'Monthly';
    case RecurringFrequency.quarterly:
      return 'Quarterly';
    case RecurringFrequency.yearly:
      return 'Yearly';
  }
}
