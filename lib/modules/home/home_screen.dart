import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              if (items.isEmpty) {
                return const Center(
                  child: Text("No Transactions"),
                );
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final tx = items[index];

                  return ListTile(
                    title: Text(
                      tx.transferAccount != null
                          ? "${tx.account.name} -> ${tx.transferAccount!.name}"
                          : tx.category.name,
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
