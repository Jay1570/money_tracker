import 'package:drift/drift.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/accounts.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  /// All non-archived accounts, ordered by creation date.
  Future<List<Account>> getAllAccounts() {
    return (select(accounts)
          ..where((a) => a.archived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .get();
  }

  /// Watch all non-archived accounts.
  Stream<List<Account>> watchAllAccounts() {
    return (select(accounts)
          ..where((a) => a.archived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .watch();
  }

  /// All accounts including archived ones.
  Future<List<Account>> getAllAccountsIncludingArchived() {
    return select(accounts).get();
  }

  /// Watch a single account by id.
  Stream<Account?> watchAccountById(int id) {
    return (select(
      accounts,
    )..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  /// Get a single account by id.
  Future<Account?> getAccountById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Accounts filtered by type.
  Stream<List<Account>> watchAccountsByType(AccountType type) {
    return (select(accounts)
          ..where((a) => a.type.equalsValue(type) & a.archived.equals(false)))
        .watch();
  }

  /// Sum of current balances across all non-archived accounts.
  Stream<double> watchTotalBalance() {
    final totalExp = accounts.currentBalance.sum();
    final query = selectOnly(accounts)
      ..addColumns([totalExp])
      ..where(accounts.archived.equals(false));
    return query.map((row) => row.read(totalExp) ?? 0).watchSingle();
  }

  Future<int> insertAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }

  Future<bool> updateAccount(AccountsCompanion entry) {
    return update(accounts).replace(entry);
  }

  /// Overwrite the current balance of an account with an absolute value.
  Future<int> updateBalance(int id, double newBalance) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(currentBalance: Value(newBalance)),
    );
  }

  /// Adjust the current balance of an account by a delta (positive or negative).
  /// Reads the current balance first, then writes the new total.
  Future<void> adjustBalance(int id, double delta) async {
    final account = await getAccountById(id);
    if (account == null) return;
    await updateBalance(id, account.currentBalance + delta);
  }

  Future<void> incrementCounter(int rowId, double delta) async {
    final account = await getAccountById(rowId);
    if (account == null) {
      throw StateError('Account $rowId not found');
    }

    final adjustedDelta = delta;

    await (update(accounts)..where((a) => a.id.equals(rowId))).write(
      AccountsCompanion.custom(
        currentBalance: accounts.currentBalance + Constant(adjustedDelta),
      ),
    );
  }

  Future<int> setArchived(int id, bool archived) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(archived: Value(archived)),
    );
  }

  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }
}
