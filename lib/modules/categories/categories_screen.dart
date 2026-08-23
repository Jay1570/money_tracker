import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/utils/category_icons_map.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/modules/transactions/add_transaction_provider.dart' show categoriesProvider;

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surfaceContainer,
        elevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.outline,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _CategoriesList(type: CategoryType.expense),
            _CategoriesList(type: CategoryType.income),
          ],
        ),
      ),
    );
  }
}

class _CategoriesList extends ConsumerWidget {
  const _CategoriesList({required this.type});

  final CategoryType type;

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return Colors.grey;
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete the category "${category.name}"?\n\n'
          'Note: Categories referenced by transactions or budgets cannot be deleted, but they can be archived.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(categoriesRepositoryProvider).deleteCategory(category.id);
        if (context.mounted) {
          AppSnackbar.showSuccess(message: 'Category deleted successfully', title: 'Success');
        }
      } catch (e) {
        // If deletion fails due to active references, suggest archiving
        if (context.mounted) {
          final archiveConfirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cannot Delete Category'),
              content: Text(
                'This category is in use and cannot be permanently deleted.\n\n'
                'Would you like to archive "${category.name}" instead? It will hide the category from pickers but keep your transaction history intact.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Archive', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          );

          if (archiveConfirm == true && context.mounted) {
            try {
              await ref.read(categoriesRepositoryProvider).archiveCategory(category.id, cascade: true);
              if (context.mounted) {
                AppSnackbar.showSuccess(message: 'Category archived successfully', title: 'Success');
              }
            } catch (err) {
              if (context.mounted) {
                AppSnackbar.showError(message: err.toString(), title: 'Error');
              }
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final colors = Theme.of(context).colorScheme;

    return categoriesAsync.when(
      data: (allCategories) {
        // Filter by current category type
        final filtered = allCategories.where((c) => c.type == type).toList();

        // Separate top-level categories and subcategories
        final topLevel = filtered.where((c) => c.parentId == null).toList();
        final subcategories = filtered.where((c) => c.parentId != null).toList();

        // Map parent ID to its subcategories
        final subMap = <int, List<Category>>{};
        for (final sub in subcategories) {
          if (sub.parentId != null) {
            subMap.putIfAbsent(sub.parentId!, () => []).add(sub);
          }
        }

        if (topLevel.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No categories yet',
                  style: TextStyle(color: colors.outline),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push('/categories/add?type=${type.name}'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            ...topLevel.expand((parent) {
              final children = subMap[parent.id] ?? [];
              final categoryColor = _parseColor(parent.color);

              return [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: categoryColor.withValues(alpha: 0.2),
                    child: Icon(
                      categoryIconFromKey(parent.icon),
                      color: categoryColor,
                    ),
                  ),
                  title: Text(
                    parent.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit',
                        onPressed: () => context.push('/categories/edit/${parent.id}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _deleteCategory(context, ref, parent),
                      ),
                    ],
                  ),
                ),
                if (children.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: children.map((child) {
                        final childColor = _parseColor(child.color);
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: childColor.withValues(alpha: 0.2),
                                child: Icon(
                                  categoryIconFromKey(child.icon),
                                  color: childColor,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                child.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    tooltip: 'Edit Subcategory',
                                    onPressed: () => context.push('/categories/edit/${child.id}'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    tooltip: 'Delete Subcategory',
                                    onPressed: () => _deleteCategory(context, ref, child),
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: colors.outlineVariant.withValues(alpha: 0.5), height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                Divider(color: colors.outlineVariant, height: 1),
              ];
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/categories/add?type=${type.name}'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
