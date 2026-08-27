import 'package:money_tracker/core/database/app_database.dart';

class RecurringTransactionWithJoin extends RecurringTransaction {
  const RecurringTransactionWithJoin({
    required super.id,
    required super.amount,
    required super.type,
    required super.accountId,
    required super.enabled,
    required super.frequency,
    required super.nextRun,
    super.categoryId,
    super.transferAccountId,
    super.note,
    required this.account,
    this.transferAccount,
    this.category,
  });

  final Account account;
  final Account? transferAccount;
  final Category? category;
}
