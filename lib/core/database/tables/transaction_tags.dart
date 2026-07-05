import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/tables/tags.dart';
import 'package:money_tracker/core/database/tables/transactions.dart';

class TransactionTags extends Table {
  IntColumn get transactionId => integer().references(Transactions, #id)();

  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {
    transactionId,
    tagId,
  };
}
