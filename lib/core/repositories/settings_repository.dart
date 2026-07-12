import 'package:money_tracker/core/database/app_database.dart';

class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  /// Settings is a single-row table; this returns that row, creating it
  /// with defaults on first access.
  Future<Setting> getSettings() => _db.settingsDao.getSettings();

  Stream<Setting> watchSettings() => _db.settingsDao.watchSettings();

  /// Updates the app's default currency. Expects an ISO 4217-style
  /// three-letter code (e.g. "INR", "USD") — anything else is almost
  /// certainly a mistake somewhere upstream (a full currency name, an
  /// empty string, etc.), so it's rejected rather than silently stored.
  Future<void> updateCurrency(String currencyCode) async {
    final normalized = currencyCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
      throw ArgumentError(
        'Currency code must be a 3-letter ISO code (e.g. "INR"), '
        'got "$currencyCode"',
      );
    }

    await _db.settingsDao.updateCurrency(normalized);
  }

  Future<void> setDarkMode(bool enabled) =>
      _db.settingsDao.updateDarkMode(enabled);
}
