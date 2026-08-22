import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/models/transaction.dart';
import 'package:money_tracker/core/utils/time_utils.dart';
import 'package:money_tracker/core/widgets/app_bar.dart';
import 'package:money_tracker/core/widgets/app_scaffold.dart';
import 'package:money_tracker/modules/home/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: const AppTopBar(
        title: "Money Tracker",
      ),
      showBottomBar: true,
      showFabButton: true,
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider).value ?? 0;
    final expense = ref.watch(monthlyExpenseProvider).value ?? 0;
    final balance = ref.watch(monthlyBalanceProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: colors.surfaceContainer,
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: "Expenses",
                  value: expense,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  title: "Income",
                  value: income,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  title: "Balance",
                  value: balance,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: transactions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (items) {
              final grouped = _groupByDay(items);

              final children = <Widget>[];
              for (final entry in grouped.entries) {
                final dayTransactions = entry.value;

                final dayIncome = dayTransactions
                    .where((t) => t.type == TransactionType.income)
                    .fold<double>(0, (sum, t) => sum + t.amount);
                final dayExpense = dayTransactions
                    .where((t) => t.type == TransactionType.expense)
                    .fold<double>(0, (sum, t) => sum + t.amount);

                children.add(
                  _DayHeader(
                    day: entry.key,
                    net: dayIncome - dayExpense,
                  ),
                );
                for (final tx in dayTransactions) {
                  children.add(_TransactionTile(tx: tx));
                }
              }

              children.add(
                _MonthNavigator(month: selectedMonth, isEmpty: items.isEmpty),
              );

              return ListView(children: children);
            },
          ),
        ),
      ],
    );
  }
}

/// Groups already date-descending-sorted transactions by calendar day.
/// Relies on same-day items being contiguous in [items] (true since the
/// underlying query orders by transactionDate desc) rather than
/// re-sorting.
Map<DateTime, List<TransactionWithJoin>> _groupByDay(
  List<TransactionWithJoin> items,
) {
  final map = <DateTime, List<TransactionWithJoin>>{};
  for (final tx in items) {
    final day = DateTime(
      tx.transactionDate.year,
      tx.transactionDate.month,
      tx.transactionDate.day,
    );
    map.putIfAbsent(day, () => []).add(tx);
  }
  return map;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.net});

  final DateTime day;
  final double net;

  @override
  Widget build(BuildContext context) {
    final isIncome = net >= 0;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${TimeUtils.dayMonthLabel(day)}  ${TimeUtils.weekdayLabel(day)}',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          Text(
            '${isIncome ? "Income" : "Expenses"}: ${net.abs().toStringAsFixed(0)}',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final TransactionWithJoin tx;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTransfer = tx.type == TransactionType.transfer;
    final isExpense = tx.type == TransactionType.expense;
    final background = isTransfer
        ? colors.primary
        : isExpense
        ? Color(0xFFba1a1a)
        : Colors.green;

    final icon = tx.type == TransactionType.transfer
        ? Icons.compare_arrows
        : isExpense
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: background,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        isTransfer
            ? "${tx.account.name} -> ${tx.transferAccount?.name ?? ''}"
            : tx.category?.name ?? tx.account.name,
      ),
      trailing: Text(
        tx.amount.toStringAsFixed(2),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => context.push('/transaction/edit/${tx.id}'),
    );
  }
}

class _MonthNavigator extends ConsumerWidget {
  const _MonthNavigator({required this.month, required this.isEmpty});

  final DateTime month;
  final bool isEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goToMonth(DateTime target) {
      ref
          .read(selectedMonthProvider.notifier)
          .setMonth(
            DateTime(
              target.year,
              target.month,
            ),
          );
    }

    final previousMonth = DateTime(month.year, month.month - 1);
    final nextMonth = DateTime(month.year, month.month + 1);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, isEmpty ? 60 : 20, 20, 20),
      child: Column(
        children: [
          if (isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "No Transactions",
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MonthPill(
                label: TimeUtils.monthYearLabel(previousMonth),
                icon: Icons.chevron_left,
                iconFirst: true,
                onTap: () => goToMonth(previousMonth),
              ),
              const SizedBox(width: 12),
              _MonthPill(
                label: TimeUtils.monthYearLabel(nextMonth),
                icon: Icons.chevron_right,
                iconFirst: false,
                onTap: () => goToMonth(nextMonth),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool iconFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final children = [
      Icon(icon, size: 18, color: colors.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst ? children : children.reversed.toList(),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.title,
    required this.value,
  });

  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
        final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
