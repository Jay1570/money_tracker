import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const databaseFileName = 'money_manager.db';

Future<String> resolveDatabaseFilePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, databaseFileName);
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final path = await resolveDatabaseFilePath();
    if (kDebugMode) {
      debugPrint(path);
    }
    return NativeDatabase.createInBackground(File(path));
  });
}
