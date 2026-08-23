import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/constants/currencies.dart';

import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/modules/reports/reports_provider.dart' show currencyCodeProvider;
import 'package:money_tracker/core/widgets/app_dropdown_field.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/core/widgets/app_text_field.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  String _name = '';
  AccountType _type = AccountType.bank;
  String _currencyCode = 'INR';
  String _amountText = '0';
  String? _nameError;
  String? _amountError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with currency setting
    _currencyCode = ref.read(currencyCodeProvider);
  }

  Future<void> _save() async {
    final trimmedName = _name.trim();
    final amount = double.tryParse(_amountText);

    if (trimmedName.isEmpty) {
      setState(() => _nameError = 'Account name is required');
    }

    if (amount == null) {
      setState(() {
        _amountError = "Invalid amount";
      });
    }

    if (_nameError != null || _amountError != null) {
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });

    try {
      await ref
          .read(accountsRepositoryProvider)
          .createAccount(
            name: trimmedName,
            type: _type,
            initialBalance: amount ?? 0,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.showError(message: e.toString(), title: "Error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xff171717),
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
          'Add',
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
            const SizedBox(height: 24),
            AppDropdownField<String>(
              labelText: 'Currency',
              value: _currencyCode,
              items: kCommonCurrencies.map((c) => c.code).toList(),
              itemLabelBuilder: (code) => currencyByCode(code).label,
              onChanged: (v) => setState(() => _currencyCode = v),
            ),
            const SizedBox(height: 24),
            AppTextField(
              value: _amountText,
              labelText: 'Amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              formatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final regex = RegExp(r'^\d*\.?\d{0,2}$');

                  if (regex.hasMatch(newValue.text)) {
                    return newValue;
                  }

                  return oldValue;
                }),
              ],
              onChanged: (v) {
                _amountText = v;
                setState(() {
                  _amountError = null;
                });
              },
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
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
