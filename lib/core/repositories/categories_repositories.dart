import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class CategoriesRepository {
  const CategoriesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Category>> watchCategories() =>
      _db.categoriesDao.watchAllCategories();

  Stream<List<Category>> watchCategoriesByType(CategoryType type) =>
      _db.categoriesDao.watchCategoriesByType(type);

  Stream<List<Category>> watchTopLevelCategories() =>
      _db.categoriesDao.watchTopLevelCategories();

  Stream<List<Category>> watchSubcategories(int parentId) =>
      _db.categoriesDao.watchSubcategories(parentId);

  Future<int> createCategory({
    required String name,
    required CategoryType type,
    int? parentId,
    String? color,
    String? icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    if (parentId != null) {
      final parent = await _db.categoriesDao.getCategoryById(parentId);
      if (parent == null) {
        throw StateError('Parent category $parentId does not exist');
      }
      if (parent.type != type) {
        throw ArgumentError(
          'Subcategory type (${type.name}) must match its parent type '
          '(${parent.type.name})',
        );
      }
    }

    return _db.categoriesDao.insertCategory(
      CategoriesCompanion.insert(
        name: trimmedName,
        type: type,
        parentId: Value(parentId),
        color: Value(color),
        icon: Value(icon),
      ),
    );
  }

  /// Updates a category's fields. Re-validates the parent relationship
  /// (matching type, no cycles) whenever `parentId` is being changed.
  Future<void> updateCategory({
    required int id,
    String? name,
    Value<int?> parentId = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
  }) async {
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final existing = await _db.categoriesDao.getCategoryById(id);
    if (existing == null) {
      throw StateError('Category $id not found');
    }

    if (parentId.present) {
      final newParentId = parentId.value;
      if (newParentId == id) {
        throw ArgumentError('A category cannot be its own parent');
      }
      if (newParentId != null) {
        final parent = await _db.categoriesDao.getCategoryById(newParentId);
        if (parent == null) {
          throw StateError('Parent category $newParentId does not exist');
        }
        if (parent.type != existing.type) {
          throw ArgumentError(
            'A category can only be nested under a parent of the same type',
          );
        }
        await _assertNoCycle(categoryId: id, proposedParentId: newParentId);
      }
    }

    await _db.categoriesDao.updateCategory(
      CategoriesCompanion(
        id: Value(id),
        name: name != null ? Value(name.trim()) : const Value.absent(),
        parentId: parentId,
        color: color,
        icon: icon,
      ),
    );
  }

  /// Walks up the ancestor chain starting at [proposedParentId] to make
  /// sure [categoryId] doesn't appear in it — which would create a loop.
  Future<void> _assertNoCycle({
    required int categoryId,
    required int proposedParentId,
  }) async {
    int? currentId = proposedParentId;
    final visited = <int>{};

    while (currentId != null) {
      if (currentId == categoryId) {
        throw ArgumentError(
          'Cannot set this parent: it would create a circular category chain',
        );
      }
      if (!visited.add(currentId)) {
        // Already-corrupt chain elsewhere in the tree; stop rather than loop.
        break;
      }
      final current = await _db.categoriesDao.getCategoryById(currentId);
      currentId = current?.parentId;
    }
  }

  /// Archives a category. If it has active subcategories, they must be
  /// archived first (or archived together via [cascade]).
  Future<void> archiveCategory(int id, {bool cascade = false}) async {
    await _db.transaction(() async {
      final children = await _db.categoriesDao.getSubcategories(id);
      final activeChildren = children.where((c) => !c.archived).toList();

      if (activeChildren.isNotEmpty && !cascade) {
        throw StateError(
          'Category $id has ${activeChildren.length} active subcategory(ies). '
          'Archive them first, or pass cascade: true.',
        );
      }

      for (final child in activeChildren) {
        await _db.categoriesDao.setArchived(child.id, true);
      }

      await _db.categoriesDao.setArchived(id, true);
    });
  }

  Future<void> unarchiveCategory(int id) {
    return _db.categoriesDao.setArchived(id, false);
  }

  /// Permanently deletes a category. Refuses if it's still referenced by
  /// any transaction, budget, or subcategory — callers should archive
  /// instead when history needs to be preserved.
  Future<void> deleteCategory(int id) async {
    final children = await _db.categoriesDao.getSubcategories(id);
    if (children.isNotEmpty) {
      throw StateError(
        'Category $id has ${children.length} subcategory(ies) and cannot '
        'be deleted. Delete or reassign them first.',
      );
    }

    final transactions = await _db.transactionsDao.getTransactionsByCategory(
      id,
    );
    if (transactions.isNotEmpty) {
      throw StateError(
        'Category $id is used by ${transactions.length} transaction(s) and '
        'cannot be deleted. Archive it instead.',
      );
    }

    final budgets = await _db.budgetsDao.getBudgetsByCategory(id);
    if (budgets.isNotEmpty) {
      throw StateError(
        'Category $id has ${budgets.length} budget(s) defined against it '
        'and cannot be deleted. Remove those budgets first.',
      );
    }

    await _db.categoriesDao.deleteCategory(id);
  }
}
