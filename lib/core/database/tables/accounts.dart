import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get type => intEnum<AccountType>()();

  RealColumn get initialBalance => real().withDefault(const Constant(0))();

  RealColumn get currentBalance => real().withDefault(const Constant(0))();

  TextColumn get color => text().nullable()();

  TextColumn get icon => text().nullable()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
