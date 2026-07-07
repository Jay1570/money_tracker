import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';

final categoriesByTypeProvider =
    StreamProvider.family<List<Category>, CategoryType>((ref, categoryType) {
      return ref
          .watch(categoriesRepositoryProvider)
          .watchCategoriesByType(categoryType);
    });

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchCategories();
});
