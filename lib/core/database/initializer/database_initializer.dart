import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/initializer/default_categories.dart';

class DatabaseInitializer {
  const DatabaseInitializer(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.transaction(() async {
      await _insertDefaultCategories();
    });
  }

  Future<void> _insertDefaultCategories() async {
    final existing = await db.categoriesDao.getAllCategories();

    if (existing.isNotEmpty) return;

    await db.batch((batch) {
      batch.insertAll(
        db.categories,
        defaultCategories.map(
          (e) => CategoriesCompanion.insert(
            name: e.name,
            type: e.type,
          ),
        ),
      );
    });
  }
}
