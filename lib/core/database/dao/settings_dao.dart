import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Settings is a single-row table (id is always 1).
  static const int _settingsId = 1;

  /// Returns the settings row, creating it with defaults if it doesn't exist.
  Future<Setting> getSettings() async {
    final existing =
        await (select(settings)..where((s) => s.id.equals(_settingsId)))
            .getSingleOrNull();
    if (existing != null) return existing;

    await into(settings).insert(
      const SettingsCompanion(id: Value(_settingsId)),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(settings)..where((s) => s.id.equals(_settingsId)))
        .getSingle();
  }

  Stream<Setting> watchSettings() {
    return (select(settings)..where((s) => s.id.equals(_settingsId)))
        .watchSingle();
  }

  Future<int> updateSettings(SettingsCompanion entry) {
    return (update(settings)..where((s) => s.id.equals(_settingsId)))
        .write(entry);
  }

  Future<int> updateCurrency(String currency) {
    return updateSettings(SettingsCompanion(currency: Value(currency)));
  }

  Future<int> updateDarkMode(bool darkMode) {
    return updateSettings(SettingsCompanion(darkMode: Value(darkMode)));
  }

  Future<int> updateBiometric(bool biometric) {
    return updateSettings(SettingsCompanion(biometric: Value(biometric)));
  }

  Future<int> updateDynamicColor(bool dynamicColor) {
    return updateSettings(
      SettingsCompanion(dynamicColor: Value(dynamicColor)),
    );
  }
}
