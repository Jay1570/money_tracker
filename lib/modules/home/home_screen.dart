import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        showMenu: true,
        showSearch: true,
        showCalendar: true,
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
              // +1 for the month navigator footer, always shown even when
              // the month has no transactions.
              return ListView.builder(
                itemCount: items.length + 1,
                itemBuilder: (_, index) {
                  if (index == items.length) {
                    return _MonthNavigator(
                      month: selectedMonth,
                      isEmpty: items.isEmpty,
                    );
                  }

                  final tx = items[index];

                  return ListTile(
                    title: Text(
                      tx.transferAccount != null
                          ? "${tx.account.name} -> ${tx.transferAccount!.name}"
                          : tx.category?.name ?? tx.account.name,
                    ),
                    subtitle: Text(tx.transactionDate.toString()),
                    trailing: Text(
                      tx.amount.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
      ref.read(selectedMonthProvider.notifier).state = DateTime(
        target.year,
        target.month,
      );
    }

    final previousMonth = DateTime(month.year, month.month - 1);
    final nextMonth = DateTime(month.year, month.month + 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, isEmpty ? 60 : 20, 20, 20),
      child: Column(
        children: [
          if (isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "No Transactions",
                style: TextStyle(color: Colors.white54),
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
    final children = [
      Icon(icon, size: 18, color: Colors.white70),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white70)),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
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
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
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
