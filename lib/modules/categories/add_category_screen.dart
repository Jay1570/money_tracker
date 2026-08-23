import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:money_tracker/core/database/tables/enums.dart';
import 'package:money_tracker/core/providers/repository_providers.dart';
import 'package:money_tracker/core/utils/category_icons_map.dart';
import 'package:money_tracker/core/widgets/app_snackbar.dart';
import 'package:money_tracker/core/widgets/app_text_field.dart';
import 'package:money_tracker/core/widgets/app_dropdown_field.dart';
import 'package:money_tracker/modules/transactions/add_transaction_provider.dart' show categoriesProvider;

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({super.key, this.categoryId, this.initialType});

  final int? categoryId;
  final CategoryType? initialType;

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  String _name = '';
  CategoryType _type = CategoryType.expense;
  int? _parentId;
  String _color = '#9C27B0'; // Default purple
  String _iconKey = 'shopping';
  String? _nameError;
  bool _saving = false;
  bool _isLoading = false;

  final List<String> _colorsList = const [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#9E9E9E', // Grey
    '#607D8B', // Blue Grey
  ];

  final List<String> _iconsList = const [
    // Expense
    'shopping',
    'food',
    'phone',
    'entertainment',
    'education',
    'beauty',
    'sports',
    'social',
    'transportation',
    'clothing',
    'car',
    'alcohol',
    'cigarettes',
    'electronics',
    'travel',
    'health',
    'pets',
    'repairs',
    'housing',
    'home',
    'gifts',
    'donations',
    'lottery',
    'snacks',
    'kids',
    'vegetables',
    'fruits',
    // Income
    'salary',
    'bonus',
    'cashback',
    'others',
    'investment',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
      _iconKey = _type == CategoryType.income ? 'salary' : 'shopping';
    }
    if (widget.categoryId != null) {
      _loadCategory();
    }
  }

  void _loadCategory() async {
    setState(() => _isLoading = true);
    try {
      final category = await ref.read(categoriesRepositoryProvider).getCategory(widget.categoryId!);
      if (category != null && mounted) {
        setState(() {
          _name = category.name;
          _type = category.type;
          _parentId = category.parentId;
          _color = category.color ?? '#9C27B0';
          _iconKey = category.icon ?? 'shopping';
        });
      }
    } catch (e) {
      AppSnackbar.showError(message: e.toString(), title: 'Error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final trimmedName = _name.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _nameError = 'Category name is required';
      });
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });

    try {
      if (widget.categoryId == null) {
        await ref.read(categoriesRepositoryProvider).createCategory(
          name: trimmedName,
          type: _type,
          parentId: _parentId,
          color: _color,
          icon: _iconKey,
        );
        AppSnackbar.showSuccess(message: 'Category created successfully', title: 'Success');
      } else {
        await ref.read(categoriesRepositoryProvider).updateCategory(
          id: widget.categoryId!,
          name: trimmedName,
          parentId: drift.Value(_parentId),
          color: drift.Value(_color),
          icon: drift.Value(_iconKey),
        );
        AppSnackbar.showSuccess(message: 'Category updated successfully', title: 'Success');
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.showError(message: e.toString(), title: 'Error');
      }
    }
  }

  Color _parseColor(String hexString) {
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surfaceContainer,
        elevation: 0,
        leadingWidth: 90,
        leading: TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        centerTitle: true,
        title: Text(
          widget.categoryId == null ? 'Add Category' : 'Edit Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
              value: _name,
              labelText: 'Name',
              isRequired: true,
              errorText: _nameError,
              onChanged: (val) => setState(() => _name = val),
            ),
            const SizedBox(height: 20),
            if (widget.categoryId == null) ...[
              Text(
                'Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.onSurface),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: _type == CategoryType.expense,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _type = CategoryType.expense;
                            _parentId = null;
                            _iconKey = 'shopping';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: _type == CategoryType.income,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _type = CategoryType.income;
                            _parentId = null;
                            _iconKey = 'salary';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            categoriesAsync.when(
              data: (list) {
                // Parents must be of same type, must be top level (parentId == null), and not this category
                final parentOptions = list.where((c) {
                  return c.type == _type &&
                      c.parentId == null &&
                      c.id != widget.categoryId;
                }).toList();

                if (parentOptions.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    AppDropdownField<int?>(
                      value: _parentId,
                      labelText: 'Parent Category (Optional)',
                      items: [null, ...parentOptions.map((c) => c.id)],
                      itemLabelBuilder: (id) {
                        if (id == null) return 'None (Top Level Category)';
                        return parentOptions.firstWhere((c) => c.id == id).name;
                      },
                      onChanged: (id) => setState(() => _parentId = id),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            Text(
              'Color',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.onSurface),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorsList.length,
                itemBuilder: (context, index) {
                  final colorHex = _colorsList[index];
                  final isSelected = _color == colorHex;
                  final parsedColor = _parseColor(colorHex);

                  return GestureDetector(
                    onTap: () => setState(() => _color = colorHex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: parsedColor,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Icon',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.onSurface),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _iconsList.length,
              itemBuilder: (context, index) {
                final iconKey = _iconsList[index];
                final isSelected = _iconKey == iconKey;
                final iconData = categoryIconFromKey(iconKey);
                final themeColor = _parseColor(_color);

                return GestureDetector(
                  onTap: () => setState(() => _iconKey = iconKey),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor.withValues(alpha: 0.2) : colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: themeColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? themeColor : colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
