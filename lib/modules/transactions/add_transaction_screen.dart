import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/utils/account_type.dart';
import 'package:money_tracker/core/utils/category_icons_map.dart';
import 'package:money_tracker/core/widgets/account_picker_sheet.dart';
import 'package:money_tracker/core/widgets/app_scaffold.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/core/widgets/numeric_keypad.dart';
import 'package:money_tracker/core/widgets/segmented_toggle.dart';
import 'package:money_tracker/modules/transactions/add_transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.isRecurring = false,
    this.transactionId,
  });

  final bool isRecurring;
  final int? transactionId;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  Category? _category;
  Account? _account;
  Account? _transferAccount;

  // Mirrors what NumericKeypad reports via onChanged — the calculator
  // state machine itself now lives inside NumericKeypad, not here.
  double _amount = 0;
  String _displayExpression = '0';

  String _note = '';
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _isLoading = false;

  // Recurring toggle — when on, saving this transaction also schedules it
  // as the template for a recurring series via
  // RecurringTransactionsRepository.scheduleRecurring.
  RecurringFrequency _frequency = RecurringFrequency.monthly;

  // Transfers don't have their own CategoryType in the schema (only
  // income/expense exist), so the transfer tab reuses the expense
  // category list — e.g. tagging a transfer as "Investment" the way the
  // recurring "SIP" transfer implied in your screenshots.
  CategoryType get _categoryTypeForTab => _type == TransactionType.income
      ? CategoryType.income
      : CategoryType.expense;

  bool get _readyForAmountEntry =>
      _account != null &&
      (_type != TransactionType.transfer || _transferAccount != null);

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransaction());
    }
  }

  Future<void> _loadTransaction() async {
    try {
      final txJoin = await ref
          .read(transactionsRepositoryProvider)
          .getTransactionById(widget.transactionId!);
      if (!mounted) return;
      if (txJoin == null) {
        AppSnackbar.showError(message: 'Transaction not found', title: 'Error');
        context.pop();
        return;
      }
      setState(() {
        _type = txJoin.type;
        _amount = txJoin.amount;
        _displayExpression = txJoin.amount.toStringAsFixed(
            txJoin.amount.truncateToDouble() == txJoin.amount ? 0 : 2);
        _category = txJoin.category;
        _account = txJoin.account;
        _transferAccount = txJoin.transferAccount;
        _note = txJoin.note ?? '';
        _date = txJoin.transactionDate;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(message: e.toString(), title: 'Error');
        context.pop();
      }
    }
  }

  void _onAmountChanged(double value, String expression) {
    setState(() {
      _amount = value;
      _displayExpression = expression;
    });
  }

  Future<void> _onCategoryTap(Category category) async {
    setState(() => _category = category);

    if (_account == null) {
      final account = await _pickAccount();
      if (account == null) return;
      setState(() => _account = account);
    }

    if (_type == TransactionType.transfer && _transferAccount == null) {
      final destination = await _pickAccount(
        title: 'Transfer To',
      );
      if (destination != null) {
        setState(() => _transferAccount = destination);
      }
    }
  }

  Future<Account?> _pickAccount({
    int? excludeAccountId,
    String title = 'Accounts',
  }) {
    return showModalBottomSheet<Account>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AccountPickerSheet(
        excludeAccountId: excludeAccountId,
        title: title,
      ),
    );
  }

  Future<void> _changeSourceAccount() async {
    final account = await _pickAccount();
    if (account != null) setState(() => _account = account);
  }

  Future<void> _changeTransferAccount() async {
    final account = await _pickAccount(
      title: 'Transfer To',
    );
    if (account != null) setState(() => _transferAccount = account);
  }

  void _changeTab(TransactionType type) {
    setState(() {
      _type = type;
      _category = null;
      _account = null;
      _transferAccount = null;
      _amount = 0;
      _displayExpression = '0';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final category = _category;
    final account = _account;
    final amount = _amount;

    if (account == null || amount <= 0) {
      AppSnackbar.showError(
        message: 'Pick an account and enter an amount',
        title: "Error",
      );
      return;
    }
    if (_type != TransactionType.transfer && category == null) {
      AppSnackbar.showError(
        message: 'Pick a category',
        title: "Error",
      );
      return;
    }
    if (_type == TransactionType.transfer && _transferAccount == null) {
      AppSnackbar.showError(
        message: 'Pick a destination account',
        title: "Error",
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(transactionsRepositoryProvider);
    final note = _note.trim().isEmpty ? null : _note.trim();

    try {
      if (widget.isEditing) {
        // --- UPDATE existing transaction ---
        final txId = widget.transactionId!;
        switch (_type) {
          case TransactionType.expense:
            await repo.updateExpense(
              transactionId: txId,
              amount: amount,
              accountId: account.id,
              categoryId: category!.id,
              note: note,
              transactionDate: _date,
            );
            break;
          case TransactionType.income:
            await repo.updateIncome(
              transactionId: txId,
              amount: amount,
              accountId: account.id,
              categoryId: category!.id,
              note: note,
              transactionDate: _date,
            );
            break;
          case TransactionType.transfer:
            await repo.updateTransfer(
              transactionId: txId,
              amount: amount,
              accountId: account.id,
              categoryId: category?.id,
              transferAccountId: _transferAccount!.id,
              note: note,
              transactionDate: _date,
            );
            break;
        }
      } else {
        // --- ADD new transaction ---
        late final int transactionId;
        switch (_type) {
          case TransactionType.expense:
            transactionId = await repo.addExpense(
              amount: amount,
              accountId: account.id,
              categoryId: category!.id,
              note: note,
              transactionDate: _date,
            );
            break;
          case TransactionType.income:
            transactionId = await repo.addIncome(
              amount: amount,
              accountId: account.id,
              categoryId: category!.id,
              note: note,
              transactionDate: _date,
            );
            break;
          case TransactionType.transfer:
            transactionId = await repo.addTransfer(
              amount: amount,
              accountId: account.id,
              categoryId: category?.id,
              transferAccountId: _transferAccount!.id,
              note: note,
              transactionDate: _date,
            );
            break;
        }

        if (widget.isRecurring) {
          final recurringRepo = ref.read(recurringTransactionsRepositoryProvider);
          await recurringRepo.scheduleRecurring(
            templateTransactionId: transactionId,
            frequency: _frequency,
            nextRun: recurringRepo.nextRunAfter(_date, _frequency),
          );
          await recurringRepo.processDueRecurringTransactions();
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.showError(message: e.toString(), title: "Error");
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
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
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .deleteTransaction(widget.transactionId!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.showError(message: e.toString(), title: 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _type != TransactionType.transfer
        ? ref.watch(
            categoriesByTypeProvider(_categoryTypeForTab),
          )
        : ref.watch(categoriesProvider);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      showFabButton: false,
      showBottomBar: false,
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
          widget.isEditing ? 'Edit' : 'Add',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete transaction',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            )
          else
            IconButton(
              tooltip: 'Recurring transactions',
              onPressed: () => context.push('/recurring-transactions'),
              icon: const Icon(Icons.event_repeat),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: SegmentedToggle<TransactionType>(
                value: _type,
                options: const [
                  TransactionType.expense,
                  TransactionType.income,
                  TransactionType.transfer,
                ],
                labelBuilder: (t) => switch (t) {
                  TransactionType.expense => 'Expense',
                  TransactionType.income => 'Income',
                  TransactionType.transfer => 'Transfer',
                },
                onChanged: _saving ? (_) {} : _changeTab,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _type == TransactionType.transfer
                        ? _TransferAccountPickerGrid(
                            fromAccount: _account,
                            toAccount: _transferAccount,
                            onPickFrom: () async {
                              final acc = await _pickAccount();
                              if (acc != null) setState(() => _account = acc);
                            },
                            onPickTo: () async {
                              final acc = await _pickAccount(title: 'Transfer To');
                              if (acc != null) setState(() => _transferAccount = acc);
                            },
                          )
                        : categoriesAsync.when(
                            data: (categories) => _CategoryGrid(
                              categories: categories,
                              selectedId: _category?.id,
                              onTap: _saving ? (_) {} : _onCategoryTap,
                            ),
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text(e.toString())),
                          ),
                  ),
                  if (_isLoading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (_readyForAmountEntry)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _AmountEntryPanel(
                        type: _type,
                        account: _account!,
                        transferAccount: _transferAccount,
                        displayAmount: _displayExpression,
                        note: _note,
                        saving: _saving,
                        dateLabel: _dateLabel(_date),
                        isRecurring: widget.isRecurring,
                        frequency: _frequency,
                        onAmountChanged: _onAmountChanged,
                        onDateTap: _pickDate,
                        onNoteChanged: (v) => _note = v,
                        onConfirm: _save,
                        onChangeSourceAccount: _changeSourceAccount,
                        onChangeTransferAccount: _changeTransferAccount,
                        onFrequencyChanged: _saving
                            ? (_) {}
                            : (f) => setState(() => _frequency = f),
                      ),
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

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (isToday) return 'Today';
  return '${date.day}/${date.month}/${date.year}';
}

String _frequencyLabel(RecurringFrequency frequency) {
  switch (frequency) {
    case RecurringFrequency.daily:
      return 'Daily';
    case RecurringFrequency.weekly:
      return 'Weekly';
    case RecurringFrequency.monthly:
      return 'Monthly';
    case RecurringFrequency.quarterly:
      return 'Quarterly';
    case RecurringFrequency.yearly:
      return 'Yearly';
  }
}

// --- Category grid --------------------------------------------------------

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onTap,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories yet',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }

    const mainAxisSpacing = 20.0;
    const crossAxisSpacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = 100.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 220),
          child: Wrap(
            spacing: crossAxisSpacing,
            runSpacing: mainAxisSpacing,
            children: [
              for (final category in categories)
                Container(
                  width: itemWidth,
                  height: itemWidth,
                  padding: EdgeInsets.all(4),
                  child: Builder(
                    builder: (context) {
                      final selected = category.id == selectedId;
                      final colors = Theme.of(context).colorScheme;

                      return InkWell(
                        onTap: () => onTap(category),
                        borderRadius: BorderRadius.circular(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: selected
                                  ? colors.primary
                                  : colors.surfaceContainer,
                              child: Icon(
                                categoryIconFromKey(category.icon),
                                color: selected
                                    ? colors.surface
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// --- Amount entry panel ---------------------------------------------------

class _AmountEntryPanel extends StatefulWidget {
  const _AmountEntryPanel({
    required this.type,
    required this.account,
    required this.transferAccount,
    required this.displayAmount,
    required this.note,
    required this.saving,
    required this.dateLabel,
    required this.isRecurring,
    required this.frequency,
    required this.onAmountChanged,
    required this.onDateTap,
    required this.onNoteChanged,
    required this.onConfirm,
    required this.onChangeSourceAccount,
    required this.onChangeTransferAccount,
    required this.onFrequencyChanged,
  });

  final TransactionType type;
  final Account account;
  final Account? transferAccount;
  final String displayAmount;
  final String note;
  final bool saving;
  final String dateLabel;
  final bool isRecurring;
  final RecurringFrequency frequency;
  final void Function(double value, String expression) onAmountChanged;
  final VoidCallback onDateTap;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onConfirm;
  final VoidCallback onChangeSourceAccount;
  final VoidCallback onChangeTransferAccount;
  final ValueChanged<RecurringFrequency> onFrequencyChanged;

  @override
  State<_AmountEntryPanel> createState() => _AmountEntryPanelState();
}

class _AmountEntryPanelState extends State<_AmountEntryPanel> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: widget.type == TransactionType.transfer
                    ? _TransferAccountsRow(
                        from: widget.account,
                        to: widget.transferAccount,
                        onTapFrom: widget.saving ? null : widget.onChangeSourceAccount,
                        onTapTo: widget.saving ? null : widget.onChangeTransferAccount,
                      )
                    : InkWell(
                        onTap: widget.saving ? null : widget.onChangeSourceAccount,
                        child: _SingleAccountRow(account: widget.account),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.displayAmount,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  'Note :',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    onChanged: widget.onNoteChanged,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter a note...',
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                  onPressed: () {
                    AppSnackbar.showError(
                      message: "Photo attachments aren't available yet",
                      title: "Error",
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _RecurringRow(
            isRecurring: widget.isRecurring,
            frequency: widget.frequency,
            enabled: !widget.saving,
            onFrequencyChanged: widget.onFrequencyChanged,
          ),
          const SizedBox(height: 8),
          NumericKeypad(
            // Switching tabs (Expense/Income/Transfer) should start the
            // calculator fresh — keying by `type` forces Flutter to
            // remount NumericKeypad with new internal state rather than
            // carrying over whatever was being typed on the previous tab.
            key: ValueKey(widget.type),
            onChanged: widget.onAmountChanged,
            onDateTap: widget.onDateTap,
            dateLabel: widget.dateLabel,
            onConfirm: widget.saving ? () {} : widget.onConfirm,
          ),
        ],
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.isRecurring,
    required this.frequency,
    required this.enabled,
    required this.onFrequencyChanged,
  });

  final bool isRecurring;
  final RecurringFrequency frequency;
  final bool enabled;
  final ValueChanged<RecurringFrequency> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_repeat,
                color: colors.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Repeat',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
              Switch(
                value: isRecurring,
                onChanged: null,
                activeThumbColor: colors.primary,
              ),
            ],
          ),
          if (isRecurring)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final option in RecurringFrequency.values)
                    ChoiceChip(
                      label: Text(_frequencyLabel(option)),
                      selected: option == frequency,
                      onSelected: enabled
                          ? (_) => onFrequencyChanged(option)
                          : null,
                      selectedColor: colors.primary,
                      labelStyle: TextStyle(
                        color: option == frequency
                            ? colors.surface
                            : colors.onSurfaceVariant,
                        fontWeight: option == frequency
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: colors.surface,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SingleAccountRow extends StatelessWidget {
  const _SingleAccountRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            accountTypeIcon(account.type),
            color: colors.surface,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            account.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _TransferAccountsRow extends StatelessWidget {
  const _TransferAccountsRow({
    required this.from,
    required this.to,
    required this.onTapFrom,
    required this.onTapTo,
  });

  final Account from;
  final Account? to;
  final VoidCallback? onTapFrom;
  final VoidCallback? onTapTo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Flexible(
          child: InkWell(
            onTap: onTapFrom,
            child: Text(
              from.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: InkWell(
            onTap: onTapTo,
            child: Text(
              to?.name ?? 'Select account',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: to == null ? colors.onSurfaceVariant : colors.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Transfer account picker grid ----------------------------------------

class _TransferAccountPickerGrid extends StatelessWidget {
  const _TransferAccountPickerGrid({
    required this.fromAccount,
    required this.toAccount,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final Account? fromAccount;
  final Account? toAccount;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _AccountPickerCard(
              account: fromAccount,
              label: 'From',
              onTap: onPickFrom,
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward, color: colors.onSurfaceVariant, size: 28),
                ],
              ),
            ),
            Expanded(child: _AccountPickerCard(
              account: toAccount,
              label: 'To',
              onTap: onPickTo,
            )),
          ],
        ),
      ),
    );
  }
}

class _AccountPickerCard extends StatelessWidget {
  const _AccountPickerCard({
    required this.account,
    required this.label,
    required this.onTap,
  });

  final Account? account;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasAccount = account != null;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: hasAccount ? colors.primary.withAlpha(30) : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasAccount ? colors.primary : colors.outlineVariant,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasAccount) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    accountTypeIcon(account!.type),
                    color: colors.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    account!.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ] else ...[
                Icon(Icons.add, size: 36, color: colors.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
