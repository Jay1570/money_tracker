import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/widgets/app_dropdown_field.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/core/widgets/app_text_field.dart';
import 'package:money_tracker/modules/accounts/view_account_screen.dart'
    show accountDetailProvider;

class EditAccountScreen extends ConsumerStatefulWidget {
  const EditAccountScreen({super.key, required this.accountId});

  final int accountId;

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  String _name = '';
  AccountType _type = AccountType.bank;
  String? _nameError;
  bool _saving = false;
  bool _initialized = false;

  void _initFrom(Account account) {
    if (_initialized) return;
    _initialized = true;
    _name = account.name;
    _type = account.type;
  }

  Future<void> _save() async {
    final trimmedName = _name.trim();
    if (trimmedName.isEmpty) {
      setState(() => _nameError = 'Account name is required');
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });

    try {
      await ref.read(accountsRepositoryProvider).updateDetails(
            id: widget.accountId,
            name: trimmedName,
            type: _type,
          );
      AppSnackbar.showSuccess(
        message: 'Account updated successfully',
        title: 'Success',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.showError(message: e.toString(), title: 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accountAsync = ref.watch(accountDetailProvider(widget.accountId));

    return accountAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (account) {
        if (account == null) {
          return const Scaffold(body: Center(child: Text('Account not found')));
        }

        // Seed the form on first build
        _initFrom(account);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colors.surfaceContainer,
            elevation: 0,
            leadingWidth: 90,
            leading: TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            centerTitle: true,
            title: const Text(
              'Edit Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    : const Icon(Icons.check),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                  value: _name,
                  labelText: 'Account name',
                  hintText: 'Enter account name',
                  isRequired: true,
                  errorText: _nameError,
                  onChanged: (v) {
                    _name = v;
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                AppDropdownField<AccountType>(
                  labelText: 'Type',
                  value: _type,
                  items: AccountType.values,
                  itemLabelBuilder: _accountTypeLabel,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'To adjust the account balance, use the adjustment (✏️) button on the account details screen.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _accountTypeLabel(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return 'Cash';
    case AccountType.bank:
      return 'Bank';
    case AccountType.creditCard:
      return 'Credit Card';
    case AccountType.investment:
      return 'Investment';
    case AccountType.loan:
      return 'Loan';
    case AccountType.asset:
      return 'Asset';
  }
}
