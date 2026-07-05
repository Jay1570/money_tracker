import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/database/tables/transactions.dart';

class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get transactionId => integer().references(Transactions, #id)();

  IntColumn get frequency => intEnum<RecurringFrequency>()();

  DateTimeColumn get nextRun => dateTime()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
