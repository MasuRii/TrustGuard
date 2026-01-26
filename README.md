# TrustGuard

TrustGuard is an offline-first group expense and settlement ledger Flutter app. It helps you track shared expenses, manage group balances, and suggests the most efficient way to settle debts among friends.

## Features

- **Offline-First**: All data is stored locally on your device using SQLite (Drift). No cloud account needed.
- **Dashboard**: Global balance overview and recent activity across all active groups.
- **Theme Customization**: Full support for Light, Dark, and System theme modes.
- **Privacy Focused**: Your financial data never leaves your device (unless you explicitly export it).
- **Group Management**: Create multiple groups for different trips, roommates, or events.
- **Flexible Expenses**: Split expenses equally or with custom amounts with real-time visual preview.
- **Modern Interactions**: Avatar-based member selection, swipe-to-action gestures, and sticky date headers.
- **Efficient Settlements**: Deterministic greedy algorithm to minimize the number of transfers needed.
- **Tagging & Filtering**: Categorize transactions with tags and find them easily with search and filters.
- **Security**: Protect your data with a PIN or biometric lock.
- **Export & Backup**: Export your data to CSV or create full JSON backups.
- **Reminders**: Schedule periodic notifications to remind the group about outstanding balances.

## Getting Started

### Prerequisites

- Flutter SDK (Stable channel)
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/MasuRii/TrustGuard.git
   ```
2. Navigate to the app directory:
   ```bash
   cd TrustGuard/app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Documentation

- [Product Specification](docs/product.md)
- [Architecture Overview](docs/architecture.md)
- [Contribution Guidelines](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)

## Localization

TrustGuard is ready for internationalization! If you would like to see the app in your language, please check the [Adding Translations](CONTRIBUTING.md#adding-translations) section in our contributing guide.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
