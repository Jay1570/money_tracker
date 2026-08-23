import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/repositories/budgets_repositories.dart';
import 'package:money_tracker/core/utils/currency_format.dart';
import 'package:money_tracker/core/utils/category_icons_map.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/modules/transactions/add_transaction_provider.dart' show categoriesProvider;
import 'package:money_tracker/modules/reports/reports_provider.dart' show currencyCodeProvider;
import 'package:money_tracker/modules/budgets/budgets_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(allBudgetsProgressProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surfaceContainer,
        elevation: 0,
        title: const Text(
          'Budgets',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: budgetsAsync.when(
          data: (items) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'No budgets defined yet',
                        style: TextStyle(color: colors.outline),
                      ),
                    ),
                  )
                else
                  for (final progress in items) ...[
                    _BudgetProgressTile(progress: progress),
                    Divider(color: colors.outlineVariant, height: 1),
                  ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/budgets/add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Budget',
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

class _BudgetProgressTile extends ConsumerWidget {
  const _BudgetProgressTile({required this.progress});

  final BudgetProgress progress;

  void _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(budgetsRepositoryProvider).deleteBudget(progress.budget.id);
        ref.invalidate(allBudgetsProgressProvider);
        AppSnackbar.showSuccess(message: 'Budget deleted successfully', title: 'Success');
      } catch (e) {
        AppSnackbar.showError(message: e.toString(), title: 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyCodeProvider);
    final colors = Theme.of(context).colorScheme;
    final budget = progress.budget;
    
    // Category lookup
    final categoryAsync = ref.watch(categoriesProvider);
    final category = categoryAsync.value?.cast<Category?>().firstWhere(
      (c) => c?.id == budget.categoryId, 
      orElse: () => null,
    );

    final categoryName = budget.categoryId == null ? 'All Categories' : (category?.name ?? 'Category');
    final categoryIcon = categoryIconFromKey(category?.icon ?? 'folder');

    final percentUsed = progress.percentUsed;
    final isOver = progress.isOverBudget;
    
    String periodText = '';
    switch (budget.period) {
      case BudgetPeriod.weekly: periodText = 'weekly'; break;
      case BudgetPeriod.monthly: periodText = 'monthly'; break;
      case BudgetPeriod.yearly: periodText = 'yearly'; break;
    }

    return InkWell(
      onTap: () => context.push('/budgets/edit/${budget.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.surfaceContainer,
                  child: Icon(categoryIcon, color: colors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Limit: $currency ${formatAmount(budget.amount)} ($periodText)',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: colors.outline),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: $currency ${formatAmount(progress.spent)}',
                  style: TextStyle(
                    color: isOver ? Colors.red : colors.outline,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isOver 
                    ? 'Over by $currency ${formatAmount(progress.spent - budget.amount)}'
                    : 'Remaining: $currency ${formatAmount(progress.remaining)}',
                  style: TextStyle(
                    color: isOver ? Colors.red : Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentUsed > 1.0 ? 1.0 : percentUsed,
                minHeight: 8,
                backgroundColor: colors.outlineVariant,
                valueColor: AlwaysStoppedAnimation(
                  isOver ? Colors.red : colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
