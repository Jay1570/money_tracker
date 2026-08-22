# Missing Features & Roadmap

This document outlines the features that are currently missing, partially implemented, or planned for future development in the Money Tracker application.

---

## 1. Partially Implemented in Database but Missing UI
* **Tags System**:
  * *Status*: Database tables (`tags` and `transaction_tags`) and DAOs exist.
  * *Missing*: No user interface to create, manage, or assign tags to transactions during creation or editing.
* **Category Customization**:
  * *Status*: A set of default categories is seeded during database initialization.
  * *Missing*: Users cannot add custom categories, edit existing category names/icons/colors, or delete categories.

## 2. Advanced Transaction Features
* **Sub-categories**:
  * *Status*: Not implemented.
  * *Missing*: Granular hierarchy for categories (e.g., `Food -> Groceries` vs `Food -> Restaurants`).
* **Multi-Currency Support**:
  * *Status*: Global currency setting exists.
  * *Missing*: Support for individual accounts/transactions in different currencies, and automatic exchange rate conversion.
* **Attachments/Receipts**:
  * *Status*: Not implemented.
  * *Missing*: Ability to attach photos of receipts, invoices, or document scans to transactions.
* **Search & Advanced Filtering**:
  * *Status*: Not implemented.
  * *Missing*: Ability to search transactions by description or filter by amount range, specific category combinations, tags, or date ranges.

## 3. Data & Syncing
* **Cloud Sync / Automated Backups**:
  * *Status*: Local manual export and import (backup `.db` sharing/restore) is implemented.
  * *Missing*: Automatic cloud syncing (e.g., via Google Drive, iCloud, Dropbox, or WebDAV) to prevent data loss.
* **CSV / Excel Export**:
  * *Status*: Not implemented.
  * *Missing*: Exporting transaction list to standard spreadsheet formats (CSV, XLSX) for personal external analysis.

## 4. Security & Privacy
* **App Lock**:
  * *Status*: Not implemented.
  * *Missing*: Biometric authentication (Fingerprint / Face ID) or PIN-code lock to secure sensitive financial data upon app startup.

## 5. UI/UX & Quality of Life
* **Savings Goals**:
  * *Status*: Not implemented.
  * *Missing*: Ability to set and track progress toward specific savings milestones.
* **Localization (i18n)**:
  * *Status*: Hardcoded strings exist across the application.
  * *Missing*: Translation setup to support multiple languages and locale-aware number/date formatting.

## 6. Testing & Quality Assurance
* **Test Coverage**:
  * *Status*: Only a boilerplate `widget_test.dart` exists.
  * *Missing*: Unit tests for repositories and providers, widget tests for screens, and integration tests for SQLite database migrations.
