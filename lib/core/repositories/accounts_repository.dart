import 'package:drift/drift.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

class AccountsRepository {
  const AccountsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Account>> watchAccounts() => _db.accountsDao.watchAllAccounts();

  Stream<Account?> watchAccount(int id) => _db.accountsDao.watchAccountById(id);

  Stream<double> watchNetWorth() => _db.accountsDao.watchTotalBalance();

  /// Creates a new account. `currentBalance` always starts out equal to
  /// `initialBalance` — it only diverges from there via transactions.
  Future<int> createAccount({
    required String name,
    required AccountType type,
    double initialBalance = 0,
    String? color,
    String? icon,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Account name cannot be empty');
    }

    return _db.accountsDao.insertAccount(
      AccountsCompanion.insert(
        name: trimmedName,
        type: type,
        initialBalance: Value(initialBalance),
        currentBalance: Value(initialBalance),
        color: Value(color),
        icon: Value(icon),
      ),
    );
  }

  /// Updates account metadata. Does *not* touch `currentBalance` — that's
  /// only ever changed indirectly through transactions or a balance
  /// recalculation, never through a direct edit here.
  ///
  /// `color`/`icon` use [Value] so callers can distinguish "leave as-is"
  /// (omit, i.e. `Value.absent()`) from "clear it" (`Value(null)`).
  Future<void> updateDetails({
    required int id,
    String? name,
    AccountType? type,
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
  }) async {
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Account name cannot be empty');
    }

    await _db.accountsDao.updateAccount(
      AccountsCompanion(
        id: Value(id),
        name: name != null ? Value(name.trim()) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        color: color,
        icon: icon,
      ),
    );
  }

  /// Corrects an account's initial balance (e.g. fixing a typo made at
  /// account creation), then recalculates the current balance from
  /// scratch so historical transactions are still reflected correctly.
  Future<void> correctInitialBalance(int id, double initialBalance) async {
    await _db.transaction(() async {
      await _db.accountsDao.updateAccount(
        AccountsCompanion(
          id: Value(id),
          initialBalance: Value(initialBalance),
        ),
      );

      final account = await _db.accountsDao.getAccountById(id);
      if (account == null) return;

      final related = await _db.transactionsDao.getTransactionsByAccount(id);
      var balance = initialBalance;
      for (final tx in related) {
        switch (tx.type) {
          case TransactionType.income:
            if (tx.accountId == id) balance += tx.amount;
            break;
          case TransactionType.expense:
            if (tx.accountId == id) balance -= tx.amount;
            break;
          case TransactionType.transfer:
            if (tx.accountId == id) balance -= tx.amount;
            if (tx.transferAccountId == id) balance += tx.amount;
            break;
        }
      }

      await _db.accountsDao.updateBalance(id, balance);
    });
  }

  /// Archives an account so it drops out of default pickers/lists, without
  /// losing its transaction history. Refuses to archive an account that
  /// still carries a non-zero balance, since that balance would otherwise
  /// silently vanish from net-worth totals.
  Future<void> archiveAccount(int id, {bool force = false}) async {
    final account = await _db.accountsDao.getAccountById(id);
    if (account == null) {
      throw StateError('Account $id not found');
    }
    if (!force && account.currentBalance != 0) {
      throw StateError(
        'Account "${account.name}" still has a balance of '
        '${account.currentBalance}. Move or settle the balance first, or '
        'pass force: true to archive anyway.',
      );
    }

    await _db.accountsDao.setArchived(id, true);
  }

  Future<void> unarchiveAccount(int id) {
    return _db.accountsDao.setArchived(id, false);
  }

  /// Permanently deletes an account. Only allowed when the account has no
  /// transaction history — otherwise deleting it would either violate the
  /// foreign key from `transactions` or silently orphan financial history.
  /// Callers wanting to "remove" an account with history should archive it
  /// instead.
  Future<void> deleteAccount(int id) async {
    final related = await _db.transactionsDao.getTransactionsByAccount(id);
    if (related.isNotEmpty) {
      throw StateError(
        'Account $id has ${related.length} transaction(s) and cannot be '
        'deleted. Archive it instead.',
      );
    }

    await _db.accountsDao.deleteAccount(id);
  }
}
