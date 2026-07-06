import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/app_database.dart';

class TagsRepository {
  const TagsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Tag>> watchTags() => _db.tagsDao.watchAllTags();

  Stream<List<Tag>> watchTagsForTransaction(int transactionId) =>
      _db.transactionTagsDao.watchTagsForTransaction(transactionId);

  Stream<List<Transaction>> watchTransactionsForTag(int tagId) =>
      _db.transactionTagsDao.watchTransactionsForTag(tagId);

  /// Creates a tag, normalizing whitespace and rejecting empty/duplicate
  /// names (name comparison is case-insensitive since two tags called
  /// "Food" and "food" would otherwise confuse users).
  Future<int> createTag(String name) async {
    final normalized = _normalize(name);
    if (normalized.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    final all = await _db.tagsDao.getAllTags();
    final duplicate = all.any(
      (t) => t.name.toLowerCase() == normalized.toLowerCase(),
    );
    if (duplicate) {
      throw StateError('A tag named "$normalized" already exists');
    }

    return _db.tagsDao.insertTag(TagsCompanion.insert(name: normalized));
  }

  Future<void> renameTag(int id, String newName) async {
    final normalized = _normalize(newName);
    if (normalized.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    final all = await _db.tagsDao.getAllTags();
    final duplicate = all.any(
      (t) => t.id != id && t.name.toLowerCase() == normalized.toLowerCase(),
    );
    if (duplicate) {
      throw StateError('A tag named "$normalized" already exists');
    }

    await _db.tagsDao.updateTag(
      TagsCompanion(id: Value(id), name: Value(normalized)),
    );
  }

  /// Deletes a tag and cleans up every transaction link that references it
  /// (the join table has no cascading delete of its own).
  Future<void> deleteTag(int id) async {
    await _db.transaction(() async {
      await _db.transactionTagsDao.clearLinksForTag(id);
      await _db.tagsDao.deleteTag(id);
    });
  }

  /// Resolves a list of freeform tag names to tag ids — reusing existing
  /// tags where the name already exists (case-insensitively) and creating
  /// new ones otherwise — then replaces the full set of tags on
  /// [transactionId] with exactly those.
  Future<void> assignTagsToTransaction({
    required int transactionId,
    required List<String> tagNames,
  }) async {
    final normalizedNames = tagNames
        .map(_normalize)
        .where((n) => n.isNotEmpty)
        .toSet() // de-duplicate within the input itself
        .toList();

    await _db.transaction(() async {
      final tagIds = <int>[];
      for (final name in normalizedNames) {
        final existing = await _db.tagsDao.getTagByName(name);
        if (existing != null) {
          tagIds.add(existing.id);
        } else {
          final id = await _db.tagsDao.insertTag(
            TagsCompanion.insert(name: name),
          );
          tagIds.add(id);
        }
      }

      await _db.transactionTagsDao.setTagsForTransaction(
        transactionId,
        tagIds,
      );
    });
  }

  String _normalize(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ');
}
