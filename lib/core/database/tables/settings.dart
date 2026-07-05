import 'package:drift/drift.dart';

class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get currency => text().withDefault(const Constant("INR"))();

  BoolColumn get darkMode => boolean().withDefault(const Constant(false))();

  BoolColumn get biometric => boolean().withDefault(const Constant(false))();

  BoolColumn get dynamicColor => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
