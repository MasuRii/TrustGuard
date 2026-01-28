# TrustGuard

TrustGuard is an offline-first group expense and settlement ledger Flutter app. It helps you track shared expenses, manage group balances, and suggests the most efficient way to settle debts among friends.

## Features

- **Offline-First**: All data is stored locally on your device using SQLite (Drift). No cloud account needed.
- **Dashboard**: Global balance overview and recent activity across all active groups with animated rolling numbers.
- **Spending Analytics**: Visualize spending by category and member with interactive pie charts and trend lines.
- **Theme Customization**: Full support for Light, Dark, and System theme modes.
- **Privacy Focused**: Your financial data never leaves your device (unless you explicitly export it).
- **Group Management**: Create multiple groups for different trips, roommates, or events.
- **Flexible Expenses**: Split expenses equally or with custom amounts with real-time visual preview. Now supports **percentage-based** splits with tactile slider controls.
- **Receipt OCR**: Automatically extract amount, date, and merchant from receipts using on-device machine learning.
- **Recurring Transactions**: Automate periodic expenses and transfers with flexible schedules.
- **Modern Interactions**: Avatar-based member selection, swipe-to-action gestures, drag-to-reorder members/tags, and glassmorphism sticky date headers.
- **Motion Design**: Smooth navigation with container transforms, staggered list animations, and celebration effects.
- **Speed Dial FAB**: Quick access to common actions and a compact **Quick Add** sheet for rapid expense entry.
- **Smart Suggestions**: Intelligent amount suggestions based on your frequent and recent spending habits.
- **Balance Visualization**: Bidirectional progress bars for a clear visual representation of member balances.
- **Undo Safety**: 5-second undo window for accidental transaction deletions.
- **Keyboard Shortcuts**: Full support for desktop power users (Ctrl/Cmd + N/T/F/S/Esc).
- **Data Import**: Seamlessly migrate from Splitwise or Tricount via CSV import with intelligent member mapping.
- **Efficient Settlements**: Deterministic greedy algorithm to minimize the number of transfers needed.
- **Tagging & Filtering**: Categorize transactions with tags and find them easily with search and filters.
- **Security**: Protect your data with a PIN or biometric lock.
- **Export & Backup**: Export your data to CSV or create full JSON backups.

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
