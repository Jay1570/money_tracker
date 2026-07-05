// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_tags_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionTagsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $TagsTable get tags => attachedDatabase.tags;
  $TransactionTagsTable get transactionTags => attachedDatabase.transactionTags;
  TransactionTagsDaoManager get managers => TransactionTagsDaoManager(this);
}

class TransactionTagsDaoManager {
  final _$TransactionTagsDaoMixin _db;
  TransactionTagsDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$TransactionTagsTableTableManager get transactionTags =>
      $$TransactionTagsTableTableManager(
        _db.attachedDatabase,
        _db.transactionTags,
      );
}
