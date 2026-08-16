import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get categoryId => integer().references(Categories, #id).nullable()();

  RealColumn get amount => real()();

  IntColumn get period => intEnum<BudgetPeriod>()();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime()();
}
