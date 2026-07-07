import 'package:flutter/material.dart';
import 'package:money_tracker/core/database/tables/enums.dart';

String accountTypeLabel(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return 'Cash';
    case AccountType.bank:
      return 'Bank';
    case AccountType.creditCard:
      return 'Credit Card';
    case AccountType.investment:
      return 'Investment';
    case AccountType.loan:
      return 'Loan';
    case AccountType.asset:
      return 'Asset';
  }
}

IconData accountTypeIcon(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return Icons.payments;
    case AccountType.bank:
      return Icons.account_balance;
    case AccountType.creditCard:
      return Icons.credit_card;
    case AccountType.investment:
      return Icons.show_chart;
    case AccountType.loan:
      return Icons.request_quote;
    case AccountType.asset:
      return Icons.home_work;
  }
}
