import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/repositories/budgets_repositories.dart';
import 'package:money_tracker/core/widgets/app_dropdown_field.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/core/widgets/app_text_field.dart';
import 'package:money_tracker/modules/transactions/add_transaction_provider.dart';
import 'package:money_tracker/modules/budgets/budgets_provider.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key, this.budgetId});

  final int? budgetId;

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  String _amountText = '0';
  int? _categoryId;
  BudgetPeriod _period = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  String? _amountError;
  bool _saving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.budgetId != null) {
      _loadBudget();
    }
  }

  void _loadBudget() async {
    setState(() => _isLoading = true);
    try {
      final progress = await ref.read(budgetsRepositoryProvider).getBudgetProgress(widget.budgetId!);
      if (progress != null && mounted) {
        final budget = progress.budget;
        setState(() {
          _amountText = budget.amount.toString();
          _categoryId = budget.categoryId;
          _period = budget.period;
          _startDate = budget.startDate;
        });
      }
    } catch (e) {
      AppSnackbar.showError(message: e.toString(), title: 'Error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _amountError = 'Amount must be greater than zero';
      });
      return;
    }

    setState(() {
      _saving = true;
      _amountError = null;
    });

    try {
      if (widget.budgetId == null) {
        await ref.read(budgetsRepositoryProvider).createBudget(
          categoryId: _categoryId,
          amount: amount,
          period: _period,
          startDate: _startDate,
        );
        AppSnackbar.showSuccess(message: 'Budget created successfully', title: 'Success');
      } else {
        await ref.read(budgetsRepositoryProvider).updateBudget(
          id: widget.budgetId!,
          amount: amount,
          period: _period,
          startDate: _startDate,
          endDate: BudgetsRepository.endDateForPeriod(_startDate, _period),
        );
        AppSnackbar.showSuccess(message: 'Budget updated successfully', title: 'Success');
      }
      ref.invalidate(allBudgetsProgressProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.showError(message: e.toString(), title: 'Error');
      }
    }
  }

  String _periodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly: return 'Weekly';
      case BudgetPeriod.monthly: return 'Monthly';
      case BudgetPeriod.yearly: return 'Yearly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(CategoryType.expense));
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        title: Text(
          widget.budgetId == null ? 'Add Budget' : 'Edit Budget',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        child: categoriesAsync.when(
          data: (categories) {
            final categoryItems = [
              Category(
                id: -1,
                name: 'All Categories (Whole Wallet)',
                type: CategoryType.expense,
                parentId: null,
                color: null,
                icon: 'folder',
                archived: false,
              ),
              ...categories
            ];

            final selectedCategory = categoryItems.firstWhere(
              (c) => c.id == (_categoryId ?? -1),
              orElse: () => categoryItems.first,
            );

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                  value: _amountText,
                  labelText: 'Budget Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  errorText: _amountError,
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
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                AppDropdownField<Category>(
                  labelText: 'Category',
                  value: selectedCategory,
                  items: categoryItems,
                  itemLabelBuilder: (c) => c.name,
                  onChanged: (c) {
                    setState(() {
                      _categoryId = c.id == -1 ? null : c.id;
                    });
                  },
                ),
                const SizedBox(height: 24),
                AppDropdownField<BudgetPeriod>(
                  labelText: 'Period',
                  value: _period,
                  items: BudgetPeriod.values,
                  itemLabelBuilder: _periodLabel,
                  onChanged: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _saving ? null : _pickDate,
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
