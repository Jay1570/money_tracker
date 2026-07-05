enum AccountType {
  cash,
  bank,
  creditCard,
  investment,
  loan,
  asset,
}

enum CategoryType {
  income,
  expense,
}

enum TransactionType {
  income,
  expense,
  transfer,
}

enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
}

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

extension AccountTypeX on AccountType {
  bool get isLiability => switch (this) {
    AccountType.creditCard => true,
    AccountType.loan => true,
    _ => false,
  };
}
