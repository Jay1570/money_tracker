import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get type => intEnum<CategoryType>()();

  IntColumn get parentId => integer().nullable().references(Categories, #id)();

  TextColumn get color => text().nullable()();

  TextColumn get icon => text().nullable()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}
