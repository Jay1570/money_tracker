# Money Tracker

A robust and modern personal finance tracker built with Flutter.

---

## 🚀 Features

* **Transaction Tracking**: Easy logging of Income, Expenses, and Transfers between accounts.
* **Smart Calculator Input**: Built-in keypad calculator within transaction input fields for quick on-the-go math (+, -, *, /).
* **Accounts Management**: Track multiple financial entities like Cash, Bank Accounts, Credit Cards, Assets, and Liabilities.
* **Monthly Budgeting**: Set budget limits per category, with clear progress bars and aggregate utilization statistics.
* **Recurring Transactions**: Automatically schedule template transactions (daily, weekly, monthly, etc.).
* **Reporting & Analytics**:
  * **Analytics Dashboard**: Overview of monthly incomes, expenses, net balance, and budget progress.
  * **Accounts Summary**: Detailed view of all account balances and net worth.
  * **Interactive Charts**: Category-wise distribution and trends using `fl_chart`.
* **Backup & Restore**: Export local database records to shareable files or import pre-existing backups.
* **Dynamic Theme & Customization**: Dynamic Material 3 support with dark and light mode preferences, and currency customization.

---

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/) (Cross-platform UI development toolkit)
* **Language**: [Dart](https://dart.dev/)
* **State Management**: [Riverpod (flutter_riverpod)](https://riverpod.dev/) (Unidirectional, compile-safe, and robust state management)
* **Local Database**: [Drift](https://drift.simonbinder.eu/) (Reactive persistence library for Flutter and Dart, built on SQLite)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router) (Declarative routing package for Flutter)
* **Charts & Visualization**: [FL Chart](https://pub.dev/packages/fl_chart) (Powerful Flutter chart library)
* **File Operations & Sharing**: [file_picker](https://pub.dev/packages/file_picker) and [share_plus](https://pub.dev/packages/share_plus) for database exports and imports.

---

## 📦 Getting Started

### Prerequisites
* Flutter SDK (recommended `^3.47` or later)
* Dart SDK

### Installation
1. Clone the repository.
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Run code generation for Drift and Freezed:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```
