import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/providers/database_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/database.dart';

/// Handles exporting the live database to a shareable file, and importing
/// a previously-exported file back in — replacing everything currently in
/// the app.
///
/// The database runs in WAL mode (see `AppDatabase.migration.beforeOpen`),
/// which means the live data on disk can be split across three files —
/// `money_manager.db`, `money_manager.db-wal`, and `money_manager.db-shm`
/// — with recently-written rows sometimes sitting only in `-wal` until a
/// checkpoint happens. That has two consequences here:
///
///  - **Export** uses `VACUUM INTO`, SQLite's built-in "safely snapshot
///    this database into one consistent file" command. It merges
///    everything — including whatever's currently only in the WAL — into
///    a single clean file, atomically, without needing to close or
///    disturb the live connection. A plain file copy of just `.db` could
///    silently miss unflushed data; this can't.
///  - **Import** has to close the live connection first (you can't safely
///    overwrite a database file out from under an open connection), then
///    explicitly deletes any leftover `-wal`/`-shm` sidecar files at the
///    destination before copying the imported file into place — so
///    nothing stale from the old database can leak into the new one.
class DatabaseBackupService {
  const DatabaseBackupService(this._db);

  final AppDatabase _db;

  /// Creates a single-file, fully-consistent snapshot of the live
  /// database in the temp directory and returns it. The app keeps
  /// running normally throughout.
  Future<File> exportToFile({String? dirPath}) async {
    String? path = dirPath;
    if (path == null) {
      final tempDir = await getTemporaryDirectory();
      path = tempDir.path;
    }
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final exportPath = p.join(
      path,
      'money_tracker_backup_$timestamp.db',
    );

    // Bound parameter rather than string interpolation — sqlite3 supports
    // a parameter for VACUUM INTO's target expression, so there's no need
    // to hand-escape the path.
    await _db.customStatement('VACUUM INTO ?;', [exportPath]);

    return File(exportPath);
  }

  /// Replaces the live database with [importedFile]'s contents.
  ///
  /// The app must be restarted afterward for the new data to take effect
  /// — this method closes the connection but deliberately doesn't try to
  /// reopen anything itself; the caller is responsible for prompting the
  /// user to restart.
  Future<void> importFromFile(File importedFile) async {
    final destinationPath = await resolveDatabaseFilePath();

    // Closing a WAL-mode connection checkpoints and cleans up its own
    // sidecar files, but we remove them explicitly too as a defensive
    // measure — belt and suspenders against any leftovers.
    debugPrint("3. Closing database");
    await _db.close();
    debugPrint("3. Closed database");

    for (final suffix in ['-wal', '-shm']) {
      final sidecar = File('$destinationPath$suffix');
      try {
        await sidecar.delete();
      } on FileSystemException catch (e) {
        // Ignore if the file doesn't exist.
        if (e.osError?.errorCode != 2) {
          rethrow;
        }
      }

    }

    await importedFile.copy(destinationPath);
  }
}

final databaseBackupServiceProvider = Provider<DatabaseBackupService>((ref) {
  return DatabaseBackupService(ref.read(databaseProvider));
});
