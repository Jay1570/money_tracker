import 'package:money_tracker/core/database/tables/enums.dart';

class DefaultCategory {
  const DefaultCategory({
    required this.name,
    required this.type,
  });

  final String name;
  final CategoryType type;
}

const defaultCategories = [
  // Income
  DefaultCategory(name: 'Salary', type: CategoryType.income),
  DefaultCategory(name: 'Bonus', type: CategoryType.income),
  DefaultCategory(name: 'Interest', type: CategoryType.income),
  DefaultCategory(name: 'Gift', type: CategoryType.income),

  // Expense
  DefaultCategory(name: 'Food', type: CategoryType.expense),
  DefaultCategory(name: 'Transport', type: CategoryType.expense),
  DefaultCategory(name: 'Shopping', type: CategoryType.expense),
  DefaultCategory(name: 'Bills', type: CategoryType.expense),
  DefaultCategory(name: 'Medical', type: CategoryType.expense),
  DefaultCategory(name: 'Entertainment', type: CategoryType.expense),
];
