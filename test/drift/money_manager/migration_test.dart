// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    
    final oldAccountsData = <v1.AccountsData>[];
    final expectedNewAccountsData = <v2.AccountsData>[];

    final oldCategoriesData = <v1.CategoriesData>[];
    final expectedNewCategoriesData = <v2.CategoriesData>[];

    final oldTransactionsData = <v1.TransactionsData>[];
    final expectedNewTransactionsData = <v2.TransactionsData>[];

    final oldTagsData = <v1.TagsData>[];
    final expectedNewTagsData = <v2.TagsData>[];

    final oldTransactionTagsData = <v1.TransactionTagsData>[];
    final expectedNewTransactionTagsData = <v2.TransactionTagsData>[];

    final oldBudgetsData = <v1.BudgetsData>[];
    final expectedNewBudgetsData = <v2.BudgetsData>[];

    final oldRecurringTransactionsData = <v1.RecurringTransactionsData>[];
    final expectedNewRecurringTransactionsData =
        <v2.RecurringTransactionsData>[];

    final oldSettingsData = <v1.SettingsData>[];
    final expectedNewSettingsData = <v2.SettingsData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.accounts, oldAccountsData);
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.transactions, oldTransactionsData);
        batch.insertAll(oldDb.tags, oldTagsData);
        batch.insertAll(oldDb.transactionTags, oldTransactionTagsData);
        batch.insertAll(oldDb.budgets, oldBudgetsData);
        batch.insertAll(
          oldDb.recurringTransactions,
          oldRecurringTransactionsData,
        );
        batch.insertAll(oldDb.settings, oldSettingsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewAccountsData,
          await newDb.select(newDb.accounts).get(),
        );
        expect(
          expectedNewCategoriesData,
          await newDb.select(newDb.categories).get(),
        );
        expect(
          expectedNewTransactionsData,
          await newDb.select(newDb.transactions).get(),
        );
        expect(expectedNewTagsData, await newDb.select(newDb.tags).get());
        expect(
          expectedNewTransactionTagsData,
          await newDb.select(newDb.transactionTags).get(),
        );
        expect(expectedNewBudgetsData, await newDb.select(newDb.budgets).get());
        expect(
          expectedNewRecurringTransactionsData,
          await newDb.select(newDb.recurringTransactions).get(),
        );
        expect(
          expectedNewSettingsData,
          await newDb.select(newDb.settings).get(),
        );
      },
    );
  });
}
