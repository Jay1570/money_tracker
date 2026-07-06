import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> getAllCategories() {
    return (select(categories)..where((c) => c.archived.equals(false))).get();
  }

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)..where((c) => c.archived.equals(false))).watch();
  }

  Future<List<Category>> getAllCategoriesIncludingArchived() {
    return select(categories).get();
  }

  Stream<List<Category>> watchCategoriesByType(CategoryType type) {
    return (select(categories)..where(
          (c) => c.type.equalsValue(type) & c.archived.equals(false),
        ))
        .watch();
  }

  /// Top-level categories only (no parent).
  Stream<List<Category>> watchTopLevelCategories() {
    return (select(
      categories,
    )..where((c) => c.parentId.isNull() & c.archived.equals(false))).watch();
  }

  /// Subcategories of a given parent category (one-off fetch).
  Future<List<Category>> getSubcategories(int parentId) {
    return (select(
      categories,
    )..where((c) => c.parentId.equals(parentId))).get();
  }

  /// Subcategories of a given parent category.
  Stream<List<Category>> watchSubcategories(int parentId) {
    return (select(categories)..where(
          (c) => c.parentId.equals(parentId) & c.archived.equals(false),
        ))
        .watch();
  }

  Stream<Category?> watchCategoryById(int id) {
    return (select(
      categories,
    )..where((c) => c.id.equals(id))).watchSingleOrNull();
  }

  Future<Category?> getCategoryById(int id) {
    return (select(
      categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Future<bool> updateCategory(CategoriesCompanion entry) {
    return update(categories).replace(entry);
  }

  Future<int> setArchived(int id, bool archived) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(archived: Value(archived)),
    );
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }
}
