import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/dao/accounts_dao.dart';
import 'package:money_tracker/core/database/dao/budgets_dao.dart';
import 'package:money_tracker/core/database/dao/categories_dao.dart';
import 'package:money_tracker/core/database/dao/recurring_transactions_dao.dart';
import 'package:money_tracker/core/database/dao/settings_dao.dart';
import 'package:money_tracker/core/database/dao/tags_dao.dart';
import 'package:money_tracker/core/database/dao/transaction_tags_dao.dart';
import 'package:money_tracker/core/database/dao/transactions_dao.dart';
import 'package:money_tracker/core/database/database.dart';
import 'package:money_tracker/core/database/initializer/database_initializer.dart';
import 'package:money_tracker/core/database/tables/accounts.dart';
import 'package:money_tracker/core/database/tables/budgets.dart';
import 'package:money_tracker/core/database/tables/categories.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/database/tables/settings.dart';
import 'package:money_tracker/core/database/tables/tags.dart';
import 'package:money_tracker/core/database/tables/transaction_tags.dart';
import 'package:money_tracker/core/database/tables/transactions.dart';
import 'package:money_tracker/core/database/tables/recurring_transaction.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Tags,
    TransactionTags,
    Budgets,
    RecurringTransactions,
    Settings,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    TransactionsDao,
    TagsDao,
    TransactionTagsDao,
    BudgetsDao,
    RecurringTransactionsDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await DatabaseInitializer(this).initialize();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
    },
    onUpgrade: (m, from, to) async {
      // Future schema migrations.
    },

  );
}
