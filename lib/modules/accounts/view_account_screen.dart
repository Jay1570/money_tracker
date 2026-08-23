import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/models/transaction.dart';
import 'package:money_tracker/core/providers/database_provider.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/utils/account_type.dart';
import 'package:money_tracker/core/utils/currency_format.dart';
import 'package:money_tracker/core/utils/time_utils.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/modules/reports/reports_provider.dart'
    show currencyCodeProvider;

final accountTransactionsProvider =
    StreamProvider.family<List<TransactionWithJoin>, int>((ref, accountId) {
      return ref
          .watch(databaseProvider)
          .transactionsDao
          .watchTransactionsByAccount(accountId);
    });

final accountDetailProvider = StreamProvider.family<Account?, int>((
  ref,
  accountId,
) {
  return ref.watch(accountsRepositoryProvider).watchAccount(accountId);
});

class ViewAccountScreen extends ConsumerWidget {
  const ViewAccountScreen({super.key, required this.accountId});

  final int accountId;

  Future<int> _getOrCreateAdjustmentCategory(
    WidgetRef ref,
    CategoryType type,
  ) async {
    final catsRepo = ref.read(categoriesRepositoryProvider);
    final allCats = await catsRepo.watchCategoriesByType(type).first;
    final adjustmentCat = allCats.cast<Category?>().firstWhere(
      (c) => c?.name.toLowerCase() == 'adjustment',
      orElse: () => null,
    );
    if (adjustmentCat != null) {
      return adjustmentCat.id;
    }
    // Create one
    return await catsRepo.createCategory(
      name: 'Adjustment',
      type: type,
      icon: 'sync',
      color: '#FFD54F',
    );
  }

  void _performEditBalance(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final controller = TextEditingController(
      text: account.currentBalance.toStringAsFixed(2),
    );
    final colors = Theme.of(context).colorScheme;

    final newBalance = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Account Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance: ${formatAmount(account.currentBalance)}',
              style: TextStyle(color: colors.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'New Balance',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.of(ctx).pop(val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newBalance != null) {
      final currentBalance = account.currentBalance;
      final diff = newBalance - currentBalance;

      if (diff == 0) return;

      try {
        final txRepo = ref.read(transactionsRepositoryProvider);
        if (diff > 0) {
          final catId = await _getOrCreateAdjustmentCategory(
            ref,
            CategoryType.income,
          );
          await txRepo.addIncome(
            amount: diff,
            accountId: account.id,
            categoryId: catId,
            note: 'Balance Adjustment',
            transactionDate: DateTime.now(),
          );
        } else {
          final catId = await _getOrCreateAdjustmentCategory(
            ref,
            CategoryType.expense,
          );
          await txRepo.addExpense(
            amount: -diff,
            accountId: account.id,
            categoryId: catId,
            note: 'Balance Adjustment',
            transactionDate: DateTime.now(),
          );
        }
        AppSnackbar.showSuccess(
          message: 'Balance adjusted successfully',
          title: 'Success',
        );
      } catch (e) {
        AppSnackbar.showError(message: e.toString(), title: 'Error');
      }
    }
  }

  void _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${account.name}"?\n\n'
          'WARNING: This will permanently delete the account and all associated transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = ref.read(databaseProvider);
        final txs = await db.transactionsDao.getTransactionsByAccount(
          account.id,
        );

        // Delete all transactions first
        for (final tx in txs) {
          await ref
              .read(transactionsRepositoryProvider)
              .deleteTransaction(tx.id, cancelRecurringSeries: true);
        }

        // Now delete the account
        await ref.read(accountsRepositoryProvider).deleteAccount(account.id);

        AppSnackbar.showSuccess(
          message: 'Account deleted successfully',
          title: 'Success',
        );
        if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        AppSnackbar.showError(message: e.toString(), title: 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountDetailProvider(accountId));
    final transactionsAsync = ref.watch(accountTransactionsProvider(accountId));
    final currency = ref.watch(currencyCodeProvider);
    final colors = Theme.of(context).colorScheme;

    return accountAsync.when(
      data: (account) {
        if (account == null) {
          return const Scaffold(
            body: Center(child: Text('Account not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colors.surfaceContainer,
            title: Text(
              account.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Account',
                onPressed: () => context.push('/account/edit/${account.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Adjustment',
                onPressed: () => _performEditBalance(context, ref, account),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteAccount(context, ref, account),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  color: colors.surfaceContainer,
                  child: Column(
                    children: [
                      Text(
                        accountTypeLabel(account.type).toUpperCase(),
                        style: TextStyle(
                          color: colors.outline,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$currency ${formatAmount(account.currentBalance)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: transactionsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No transactions for this account',
                            style: TextStyle(color: colors.outline),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: items.length,
                        itemBuilder: (ctx, index) {
                          final tx = items[index];
                          final isTransfer =
                              tx.type == TransactionType.transfer;
                          final isExpense = tx.type == TransactionType.expense;

                          final background = isTransfer
                              ? colors.primary
                              : isExpense
                              ? const Color(0xFFba1a1a)
                              : Colors.green;

                          final icon = isTransfer
                              ? Icons.compare_arrows
                              : isExpense
                              ? Icons.arrow_upward
                              : Icons.arrow_downward;

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: background,
                                  child: Icon(icon, color: Colors.white),
                                ),
                                title: Text(
                                  isTransfer
                                      ? "${tx.account.name} -> ${tx.transferAccount?.name ?? ''}"
                                      : (tx.category?.name ?? 'Adjustment'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${TimeUtils.dayMonthLabel(tx.transactionDate)} ${tx.note ?? ""}',
                                  style: TextStyle(
                                    color: colors.outline,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  '${isTransfer
                                      ? ""
                                      : isExpense
                                      ? "-"
                                      : "+"}$currency ${formatAmount(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isTransfer
                                        ? colors.onSurface
                                        : isExpense
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                onTap: () =>
                                    context.push('/transaction/edit/${tx.id}'),
                              ),
                              Divider(color: colors.outlineVariant, height: 1),
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(e.toString())),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }
}
