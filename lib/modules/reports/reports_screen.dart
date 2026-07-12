import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/utils/account_type.dart';
import 'package:money_tracker/core/utils/currency_format.dart';
import 'package:money_tracker/core/utils/time_utils.dart';
import 'package:money_tracker/core/widgets/app_bar.dart';
import 'package:money_tracker/core/widgets/app_scaffold.dart';
import 'package:money_tracker/core/widgets/section_card.dart';
import 'package:money_tracker/core/widgets/segmented_toggle.dart';
import 'package:money_tracker/modules/reports/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(reportsTabProvider);

    return AppScaffold(
      appBar: const AppTopBar(
        title: 'Reports',
        showMenu: false,
        showSearch: false,
        showCalendar: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SegmentedToggle<ReportsTab>(
              value: tab,
              options: ReportsTab.values,
              labelBuilder: (t) =>
                  t == ReportsTab.analytics ? 'Analytics' : 'Accounts',
              onChanged: (t) => ref.read(reportsTabProvider.notifier).state = t,
            ),
          ),
          Expanded(
            child: tab == ReportsTab.analytics
                ? const _AnalyticsTab()
                : const _AccountsTab(),
          ),
        ],
      ),
    );
  }
}

// --- Analytics tab -----------------------------------------------------

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(reportsMonthlyIncomeProvider).value ?? 0;
    final expense = ref.watch(reportsMonthlyExpenseProvider).value ?? 0;
    final balance = ref.watch(reportsMonthlyBalanceProvider);
    final aggregatedBudget = ref.watch(aggregatedBudgetProvider);
    final monthLabel = TimeUtils.monthAbbreviations[DateTime.now().month - 1];
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(title: 'Monthly Statistics'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    monthLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatColumn(label: 'Expenses', value: expense),
                  ),
                  Expanded(
                    child: _StatColumn(label: 'Income', value: income),
                  ),
                  Expanded(
                    child: _StatColumn(label: 'Balance', value: balance),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(title: 'Monthly Budget'),
              const SizedBox(height: 20),
              if (aggregatedBudget == null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No active budgets this month',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              else
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: CircularProgressIndicator(
                              value: aggregatedBudget.percentRemaining
                                  .toDouble(),
                              strokeWidth: 10,
                              backgroundColor: colors.onSurfaceVariant,
                              valueColor: AlwaysStoppedAnimation(
                                colors.primary,
                              ),
                            ),
                          ),
                          Text(
                            'Remaining\n${(aggregatedBudget.percentRemaining * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _BudgetRow(
                            label: 'Remaining',
                            value: aggregatedBudget.remaining,
                          ),
                          Divider(color: colors.outlineVariant, height: 20),
                          _BudgetRow(
                            label: 'Budget',
                            value: aggregatedBudget.budget,
                          ),
                          Divider(color: colors.outlineVariant, height: 20),
                          _BudgetRow(
                            label: 'Expenses',
                            value: aggregatedBudget.spent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          formatAmount(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label :', style: TextStyle(color: colors.onSurfaceVariant)),
        Text(
          formatAmount(value),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _AccountsTab extends ConsumerWidget {
  const _AccountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorth = ref.watch(netWorthProvider).value ?? 0;
    final assetsLiabilities = ref.watch(assetsAndLiabilitiesProvider);
    final grouped = ref.watch(groupedAccountsProvider);
    final currency = ref.watch(currencyCodeProvider).value ?? 'INR';
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        SectionCard(
          child: Stack(
            children: [
              Positioned(
                right: -4,
                top: -4,
                child: Icon(
                  Icons.savings,
                  size: 56,
                  color: colors.outlineVariant,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Worth',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatAmount(netWorth),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _NetWorthColumn(
                          label: 'Assets',
                          value: assetsLiabilities.assets,
                        ),
                      ),
                      Expanded(
                        child: _NetWorthColumn(
                          label: 'Liabilities',
                          value: assetsLiabilities.liabilities,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (grouped.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No accounts yet',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final entry in grouped.entries) ...[
            _AccountGroupHeader(
              type: entry.key,
              total: entry.value.fold<double>(
                0,
                (sum, a) => sum + a.currentBalance,
              ),
            ),
            for (final account in entry.value)
              _AccountTile(account: account, currency: currency),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push('/account/add'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.surface,
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
  }
}

class _NetWorthColumn extends StatelessWidget {
  const _NetWorthColumn({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          formatAmount(value),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AccountGroupHeader extends StatelessWidget {
  const _AccountGroupHeader({required this.type, required this.total});

  final AccountType type;
  final double total;

  @override
  Widget build(BuildContext context) {
    final isLiabilityGroup = type.isLiability;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            accountTypeLabel(type),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          Text(
            isLiabilityGroup
                ? 'Liabilities : ${formatAmount(total.abs())}'
                : formatAmount(total),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.currency});

  final Account account;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLiability = account.type.isLiability;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(accountTypeIcon(account.type), color: colors.surface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              account.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isLiability)
                Text(
                  '( I owe )',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              Text(
                '$currency ${formatAmount(account.currentBalance)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colors.outlineVariant, size: 20),
        ],
      ),
    );
  }
}
