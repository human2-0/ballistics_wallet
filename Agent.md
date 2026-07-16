# Agent navigation map

Use this file to reach the relevant code without rescanning the repository. Paths are relative to this repository root.

## Mental model

This is a Flutter app with Riverpod state. UI widgets read providers; providers coordinate models and repositories; repositories talk to Firebase, Hive, Google Drive, or the local filesystem.

- Shared product definitions and Firebase user bootstrap data are remote.
- Wallet history, user settings, selections, and most preferences are local Hive data.
- Google Drive is used for opt-in Hive backups and developer intake of product images, not as the live image CDN.

## Start here

| Concern | Primary path | Notes |
| --- | --- | --- |
| Process entry | `lib/main.dart` | Initializes Liquid Glass, app services, Riverpod, and `MaterialApp.router`. |
| Startup services | `lib/app_initializer.dart` | Firebase, Crashlytics, Hive, notifications, and Google Sign-In initialization. |
| Routes/auth gate | `lib/providers/router_provider.dart` | All GoRouter paths and allowed-email redirect logic. |
| Main tab shell | `lib/ui/pressing/bottom_app_bar.dart` | Owns Target, Split, Wallet, and Profile tabs. |
| Target calculator | `lib/ui/pressing/target_check/` | Main tree, shift calculators, product lookup/editing, save flow, and work timeline. |
| Split calculator | `lib/ui/pressing/split_check/` | Split-check UI; state is in `lib/providers/split_provider.dart`. |
| Wallet | `lib/ui/pressing/wallet/` | Calendar, history, statistics, and add/edit sheets. |
| Profile/settings | `lib/ui/pressing/profile/` | User settings, backup/restore, policies, and timeline reminders. |
| Reusable UI | `lib/custom_widgets/` | Notifications, text fields, keyboard dismissal, and product image rendering. |
| State layer | `lib/providers/` | Riverpod providers/notifiers grouped by feature. |
| Data access | `lib/repository/` | Firebase Auth/Firestore, Hive, Drive backup, and product-image intake. |
| Domain objects | `lib/models/` | Hive models and calculator/value objects. |
| Local bootstrap | `lib/utilities.dart` | Hive adapters/boxes and bundled CSV product seeding. |
| Platform services | `lib/services/` | Crash reporting and local work-timeline notifications. |
| Firebase config | `firebase.json`, `lib/firebase_options.dart` | Project/platform wiring; treat platform credential files as sensitive. |

## High-value flows

### Startup and navigation

`lib/main.dart` -> `lib/app_initializer.dart` -> `lib/providers/router_provider.dart` -> `lib/ui/pressing/bottom_app_bar.dart` -> feature screen.

The auth provider is `lib/providers/auth_providers/auth_provider.dart`; the state/controller files beside it drive `lib/ui/login_screen.dart`. Route changes should be covered by `test/router_provider_test.dart`.

### Product target calculation

`target_checker_main_tree.dart` -> `basic_shift/` or `overtime_shift/` -> `lib/providers/target_check_provider.dart` plus `lib/providers/bonus_tables_provider.dart` -> models in `lib/models/product_info.dart`.

Product selection and editing live under `look_up_bar/`. The shared catalog flows through `lib/providers/product_info_provider.dart` into `lib/repository/product_info_repository.dart`.

### Wallet save and totals

Target/save UI -> `lib/providers/add_bonus_info_notifier_provider.dart` -> `bonusInfoListProvider` in `lib/providers/wallet_providers.dart` -> `lib/repository/bonus_info_repository.dart` -> Hive `bonusInfoBox`.

Wallet summaries, date ranges, paycheck-month history, and filters are concentrated in `lib/providers/wallet_providers.dart`; UI rendering stays in `lib/ui/pressing/wallet/`.

### Product images

`lib/custom_widgets/product_image_view.dart` -> `lib/providers/product_image_provider.dart` -> `lib/repository/product_image_repository.dart`. Read `docs/product-image-architecture.md` before changing this flow. Developer sync tools are in `scripts/check_lush_assets.py` and `scripts/check_lush_assets.command`.

### Backup and restore

Profile tiles -> `lib/providers/back_up_provider.dart` -> `lib/repository/back_up_repository.dart` -> a bounded ZIP of the Hive directory -> Google Drive file `BallisticsWalletBackup.zip`.

## Backend and persistence contracts

| Store | Contract | Owning code |
| --- | --- | --- |
| Firebase Auth | Email/password and Google sign-in | `lib/repository/auth_repository.dart` |
| Firestore | `targets/pressing`: one document whose top-level keys are product names | `lib/repository/product_info_repository.dart` |
| Firestore | `users/{uid}`: bootstrap profile metadata | `lib/repository/auth_repository.dart` |
| Hive | `bonusInfoBox`, `settings`, `customDateRangeBox`, `selected_products`, split/timeline preference boxes | `lib/utilities.dart` and feature repositories/providers |
| Google Drive | Backup ZIP and `lush_assets` developer image-intake folder | `lib/repository/back_up_repository.dart`, `lib/repository/product_image_repository.dart` |

`lib/repository/outdated_pressing_db_repository.dart` and `lib/providers/pressing_db_provider.dart` describe the older Firestore `userBonuses/.../produced` path. Confirm a live call site before extending them.

## Change routing

- Authentication or redirects: `auth_repository.dart` -> auth providers/controller -> `router_provider.dart` -> login/router tests.
- Product schema or target math: `product_info.dart` -> `product_info_repository.dart` -> product/target providers -> lookup and target tests.
- Wallet math or date behavior: `bonus_info.dart` -> `wallet_providers.dart` -> wallet UI -> `test/wallet/`.
- Work timeline: `work_timeline_plan.dart` -> `work_timeline_provider.dart` -> `work_timeline_panel.dart` -> `test/target_check/work_timeline_plan_test.dart`.
- Hive schema: model annotations + generated `*.g.dart` + adapter registration/migration in `utilities.dart` + repository tests.
- Native release/config: `android/`, `ios/`, `macos/`, and `docs/ios-release.md`; avoid `ios_backup/`.

## Commands

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

For a focused test, prefer `flutter test test/<feature>_test.dart`. Run `dart run build_runner build --delete-conflicting-outputs` only when a Hive or mock generator input changed.

## Avoid broad scans

Skip `build/`, `.dart_tool/`, `ios/Pods/`, `macos/Pods/`, `ios_backup/`, generated `*.g.dart`, generated `*.mocks.dart`, and `lib/oss_licenses.dart` unless the task explicitly targets them. Do not hand-edit generated Firebase options or generated native plugin files.

Preserve unrelated working-tree changes. Keep secrets and recovery/credential material out of logs, fixtures, and commits.
