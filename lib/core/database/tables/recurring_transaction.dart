import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/tables/accounts.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Template fields — no longer a reference to a real Transaction.
  RealColumn get amount => real()();

  IntColumn get type => intEnum<TransactionType>()();

  @ReferenceName("sourceAccount")
  IntColumn get accountId => integer().references(Accounts, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  @ReferenceName("transaferAccount")
  IntColumn get transferAccountId =>
      integer().nullable().references(Accounts, #id)();

  TextColumn get note => text().nullable()();

  IntColumn get frequency => intEnum<RecurringFrequency>()();

  DateTimeColumn get nextRun => dateTime()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
