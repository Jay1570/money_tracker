import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/tags.dart';
import 'package:money_tracker/core/database/tables/transaction_tags.dart';
import 'package:money_tracker/core/database/tables/transactions.dart';

part 'transaction_tags_dao.g.dart';

@DriftAccessor(tables: [TransactionTags, Tags, Transactions])
class TransactionTagsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionTagsDaoMixin {
  TransactionTagsDao(super.db);

  /// All tags linked to a given transaction.
  Stream<List<Tag>> watchTagsForTransaction(int transactionId) {
    final query = select(tags).join([
      innerJoin(
        transactionTags,
        transactionTags.tagId.equalsExp(tags.id),
      ),
    ])..where(transactionTags.transactionId.equals(transactionId));

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(tags)).toList(),
    );
  }

  Future<List<Tag>> getTagsForTransaction(int transactionId) {
    final query = select(tags).join([
      innerJoin(
        transactionTags,
        transactionTags.tagId.equalsExp(tags.id),
      ),
    ])..where(transactionTags.transactionId.equals(transactionId));

    return query.get().then(
      (rows) => rows.map((row) => row.readTable(tags)).toList(),
    );
  }

  /// All transactions linked to a given tag.
  Stream<List<Transaction>> watchTransactionsForTag(int tagId) {
    final query = select(transactions).join([
      innerJoin(
        transactionTags,
        transactionTags.transactionId.equalsExp(transactions.id),
      ),
    ])..where(transactionTags.tagId.equals(tagId));

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(transactions)).toList(),
    );
  }

  /// Remove all transaction links for a given tag (e.g. before deleting
  /// the tag itself, since the join table has no cascading delete).
  Future<int> clearLinksForTag(int tagId) {
    return (delete(
      transactionTags,
    )..where((tt) => tt.tagId.equals(tagId))).go();
  }

  Future<int> addTagToTransaction(int transactionId, int tagId) {
    return into(transactionTags).insert(
      TransactionTagsCompanion.insert(
        transactionId: transactionId,
        tagId: tagId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> removeTagFromTransaction(int transactionId, int tagId) {
    return (delete(transactionTags)..where(
          (tt) =>
              tt.transactionId.equals(transactionId) & tt.tagId.equals(tagId),
        ))
        .go();
  }

  /// Remove all tag links for a transaction (e.g. before re-assigning tags).
  Future<int> clearTagsForTransaction(int transactionId) {
    return (delete(
      transactionTags,
    )..where((tt) => tt.transactionId.equals(transactionId))).go();
  }

  /// Replace all tags for a transaction with the given tag ids.
  Future<void> setTagsForTransaction(
    int transactionId,
    List<int> tagIds,
  ) async {
    await batch((b) {
      b.deleteWhere(
        transactionTags,
        (tt) => tt.transactionId.equals(transactionId),
      );
      b.insertAll(
        transactionTags,
        tagIds.map(
          (tagId) => TransactionTagsCompanion.insert(
            transactionId: transactionId,
            tagId: tagId,
          ),
        ),
      );
    });
  }
}
