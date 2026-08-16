import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/utils/account_type.dart';
import 'package:money_tracker/core/utils/currency_format.dart';
import 'package:money_tracker/modules/reports/reports_provider.dart';

/// The "Accounts" bottom sheet shown when picking a source/destination
/// account for a transaction. Returns the selected [Account] via
/// `Navigator.pop(account)`, or `null` if dismissed.
class AccountPickerSheet extends ConsumerWidget {
  const AccountPickerSheet({
    super.key,
    this.excludeAccountId,
    this.title = 'Accounts',
  });

  /// An account id to hide from the list — used for the transfer
  /// destination picker so you can't transfer an account into itself.
  final int? excludeAccountId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox.shrink(),
              ],
            ),
          ),
          Flexible(
            child: accountsAsync.when(
              data: (accounts) {
                final filtered = accounts
                    .where((a) => a.id != excludeAccountId)
                    .toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No accounts available',
                      style: TextStyle(color: colors.outline),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outline),
                  itemBuilder: (_, index) {
                    final account = filtered[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          accountTypeIcon(account.type),
                          color: colors.surface,
                        ),
                      ),
                      title: Text(account.name),
                      trailing: Text(
                        formatAmount(account.currentBalance),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () => context.pop(account),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
