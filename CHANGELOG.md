# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-01-27

### Added
- **Global Dashboard**: New home screen overview showing total debt/credit across all active groups and recent activity.
- **Theme Customization**: Support for Light, Dark, and System theme modes with persistence.
- **Modern Member Selection**: Replaced legacy dropdowns and checkboxes with horizontal avatar selectors for better UX.
- **Visual Split Preview**: Real-time proportional bar chart for expense splits, providing immediate feedback on distribution.
- **Sticky Date Headers**: Transaction list now groups items by date with modern headers.
- **Swipe Actions**: Quick swipe-to-edit and swipe-to-delete gestures for transactions.
- **Contextual Settlements**: Reorganized settlements screen to prioritize actions you need to take.
- **Skeleton Loading**: Improved perceived performance with shimmer-based loading placeholders.
- **SVG Illustrations**: Custom vector illustrations for empty states.
- **Haptic Feedback**: Tactile feedback for key interactions like button presses and selection changes.
- **Hero Animations**: Smooth visual transitions between lists and detail screens.
- **Integration Testing**: Comprehensive end-to-end user flow tests.

### Changed
- Improved `EmptyState` component to support both icons and SVG paths.
- Optimized balance aggregation logic for cross-group summaries.
- Updated user guide with new UI/UX features.

### Fixed
- Resolved minor layout shifts during data loading.
- Fixed inconsistent tag display in filtered lists.

## [1.1.0] - 2026-01-15
- Initial stable release with core features: Offline storage, group management, basic expenses/transfers, search/filters, PIN lock, and CSV export.
