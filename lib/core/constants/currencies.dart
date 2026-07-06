/// A minimal currency reference used by account-creation UI.
///
/// The app already has a `Currencies` table (code/symbol/name) in the
/// schema, but it isn't registered on [AppDatabase] or seeded with data
/// yet — so this list stands in for it for now. If you want the picker
/// backed by the real table (e.g. so it's editable/extendable without a
/// code change), that table needs to be added to `AppDatabase`'s `tables:`
/// list, given a DAO, and seeded with ISO 4217 currency data.
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;

  String get label => '$code ( $symbol )   $name';
}

const List<CurrencyInfo> kCommonCurrencies = [
  CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
  CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
  CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  CurrencyInfo(code: 'AUD', symbol: '\$', name: 'Australian Dollar'),
  CurrencyInfo(code: 'CAD', symbol: '\$', name: 'Canadian Dollar'),
  CurrencyInfo(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
  CurrencyInfo(code: 'SGD', symbol: '\$', name: 'Singapore Dollar'),
];

CurrencyInfo currencyByCode(String code) {
  return kCommonCurrencies.firstWhere(
    (c) => c.code == code,
    orElse: () => kCommonCurrencies.first,
  );
}
