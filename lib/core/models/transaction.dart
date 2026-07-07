import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class TransactionWithJoin {
  final int id;
  final double amount;
  final TransactionType type;
  final int accountId;
  final int? categoryId;
  final int? transferAccountId;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;
  final Account account;
  final Account? transferAccount;
  final Category category;
  const TransactionWithJoin({
    required this.id,
    required this.amount,
    required this.type,
    required this.accountId,
    this.categoryId,
    this.transferAccountId,
    this.note,
    required this.transactionDate,
    required this.createdAt,
    required this.account,
    this.transferAccount,
    required this.category,
  });
}
