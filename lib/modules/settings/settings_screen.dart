import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_tracker/core/services/database_backup_service.dart';
import 'package:money_tracker/core/widgets/app_scaffold.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:share_plus/share_plus.dart';

import 'package:money_tracker/core/constants/currencies.dart';
import 'package:money_tracker/core/providers/database_provider.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/modules/reports/reports_provider.dart'
    show reportsTabProvider, ReportsTab;
import 'package:money_tracker/modules/settings/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: colors.surfaceContainer,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      showBottomBar: true,
      showFabButton: false,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SectionLabel('General'),
            _SettingsCard(
              children: _withDividers(
                color: colors.outlineVariant,
                tiles: [
                  _CurrencyTile(currentCode: settings.currency),
                  _SwitchTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: settings.darkMode,
                    onChanged: (v) =>
                        ref.read(settingsRepositoryProvider).setDarkMode(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Manage'),
            _SettingsCard(
              children: _withDividers(
                color: colors.outlineVariant,
                tiles: [
                  _NavTile(
                    icon: Icons.account_balance_outlined,
                    label: 'Accounts',
                    onTap: () {
                      ref.read(reportsTabProvider.notifier).state =
                          ReportsTab.accounts;
                      context.go('/reports');
                    },
                  ),
                  _NavTile(
                    icon: Icons.event_repeat,
                    label: 'Recurring Transactions',
                    onTap: () => context.push('/recurring-transactions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Data'),
            _SettingsCard(
              children: _withDividers(
                color: colors.outlineVariant,
                tiles: [
                  _NavTile(
                    icon: Icons.upload_outlined,
                    label: 'Export Database',
                    onTap: () => _exportDatabase(context, ref),
                  ),
                  _NavTile(
                    icon: Icons.download_outlined,
                    label: 'Import Database',
                    danger: true,
                    onTap: () => _importDatabase(context, ref),
                  ),
                  _NavTile(
                    icon: Icons.calculate_outlined,
                    label: 'Recalculate All Balances',
                    onTap: () => _recalculateBalances(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interleaves a divider between each pair of tiles (none before the
/// first or after the last) — keeps the conditional-tile lists above from
/// needing manual divider bookkeeping.
List<Widget> _withDividers({
  required List<Widget> tiles,
  required Color color,
}) {
  final result = <Widget>[];
  for (var i = 0; i < tiles.length; i++) {
    if (i > 0) result.add(Divider(height: 1, color: color));
    result.add(tiles[i]);
  }
  return result;
}

/// Shows a non-dismissible "working" dialog — no tap-outside, no back
/// button — for operations like import where letting the user navigate
/// away or interrupt mid-operation would be actively dangerous (a
/// half-replaced database file).
void _showLoadingDialog(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: true,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

/// Dismisses whatever dialog _showLoadingDialog pushed. Goes through
/// rootNavigatorKey (reliable even if the screen that triggered the
/// operation has since been navigated away from) and Navigator directly
/// — not context.pop(), which with go_router imported resolves to
/// GoRouter's own pop() and operates on the router's route stack, not the
/// plain Navigator that showDialog() actually pushed the dialog onto.
/// Those are two different stacks; GoRouter's pop() isn't reliable for
/// dismissing a dialog pushed that way.
void _dismissLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

Future<void> _exportDatabase(BuildContext context, WidgetRef ref) async {
  try {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select where to save export",
    );

    final file = await ref
        .read(databaseBackupServiceProvider)
        .exportToFile(dirPath: selectedDirectory);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Money Tracker backup'),
    );
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.showError(
        message: 'Export failed: $e',
        title: "Export failed",
      );
    }
  }
}

Future<void> _importDatabase(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles();
  final pickedPath = result?.files.single.path;

  if (pickedPath == null) {
    // Was previously a silent no-op — file_picker commonly fails to
    // resolve a real filesystem path for files received via a share
    // sheet, cloud storage app, or AirDrop rather than picked from local
    // storage, so this needs to be visible rather than doing nothing.
    if (context.mounted) {
      AppSnackbar.showError(
        message:
            "Couldn't access that file. Try saving it to local storage "
            'first, then pick it from there.',
        title: 'Import failed',
      );
    }
    return;
  }

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Replace all data?'),
      content: const Text(
        'Importing a backup replaces everything currently in the app — '
        'all accounts, transactions, categories, and budgets. This cannot '
        'be undone. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          child: const Text(
            'Replace',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  if (context.mounted) {
    _showLoadingDialog(context, 'Importing database...');
  }

  try {
    ref.invalidate(databaseProvider);

    await ref
        .read(databaseBackupServiceProvider)
        .importFromFile(File(pickedPath));

    ref.invalidate(databaseProvider);

    if (context.mounted) {
      _dismissLoadingDialog(context);
    }

    if (context.mounted) {
      AppSnackbar.show(
        message: 'Import complete — data reloaded',
        title: "Success",
        type: SnackbarType.success,
      );
    }
  } catch (e) {
    if (context.mounted) {
      _dismissLoadingDialog(context);
    }
    AppSnackbar.showError(
      message: 'Import failed: $e',
      title: 'Import failed',
    );
  }
}

Future<void> _recalculateBalances(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(transactionsRepositoryProvider).recalculateAllBalances();
    if (context.mounted) {
      AppSnackbar.show(
        type: SnackbarType.success,
        message: 'Balances recalculated',
        title: "Success",
      );
    }
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.showError(
        message: 'Failed:- $e',
        title: "Error",
      );
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(children: children),
    );
  }
}

class _CurrencyTile extends ConsumerWidget {
  const _CurrencyTile({required this.currentCode});

  final String currentCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final value = kCommonCurrencies.any((c) => c.code == currentCode)
        ? currentCode
        : kCommonCurrencies.first.code;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.currency_exchange, color: colors.onSurfaceVariant),
          const SizedBox(width: 16),
          const Expanded(child: Text('Currency')),
          DropdownButton<String>(
            value: value,
            dropdownColor: colors.surfaceContainerHigh,
            underline: const SizedBox.shrink(),
            items: kCommonCurrencies
                .map(
                  (c) => DropdownMenuItem(value: c.code, child: Text(c.code)),
                )
                .toList(),
            onChanged: (code) async {
              if (code == null) return;
              try {
                await ref.read(settingsRepositoryProvider).updateCurrency(code);
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.showError(
                    message: e.toString(),
                    title: "Error",
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colors.onSurfaceVariant),
      title: Text(label),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: colors.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = danger ? Colors.redAccent : colors.onSurface;

    return ListTile(
      leading: Icon(
        icon,
        color: danger ? Colors.redAccent : colors.onSurfaceVariant,
      ),
      title: Text(label, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: colors.outlineVariant),
      onTap: onTap,
    );
  }
}
