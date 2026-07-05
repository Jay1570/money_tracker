import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/tags.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Future<List<Tag>> getAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Stream<List<Tag>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Stream<Tag?> watchTagById(int id) {
    return (select(tags)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<Tag?> getTagById(int id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Tag?> getTagByName(String name) {
    return (select(tags)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
  }

  Future<int> insertTag(TagsCompanion entry) {
    return into(tags).insert(entry);
  }

  /// Insert a tag by name if it doesn't already exist, returning its id.
  Future<int> getOrCreateTag(String name) async {
    final existing = await getTagByName(name);
    if (existing != null) return existing.id;
    return insertTag(TagsCompanion.insert(name: name));
  }

  Future<bool> updateTag(TagsCompanion entry) {
    return update(tags).replace(entry);
  }

  Future<int> deleteTag(int id) {
    return (delete(tags)..where((t) => t.id.equals(id))).go();
  }
}
