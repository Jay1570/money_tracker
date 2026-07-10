import 'package:money_tracker/core/database/app_database.dart';

class TransactionWithJoin extends Transaction {
  const TransactionWithJoin({
    required super.id,
    required super.amount,
    required super.type,
    required super.accountId,
    super.categoryId,
    super.transferAccountId,
    super.note,
    required super.transactionDate,
    required super.createdAt,
    required this.account,
    this.transferAccount,
    this.category,
  });

  final Account account;
  final Account? transferAccount;
  final Category? category;
}
