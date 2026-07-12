import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';

final settingsStreamProvider = StreamProvider<Setting>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});
