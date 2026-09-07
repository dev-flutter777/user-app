# Customer journey validation — 2026-09-07

Source: `E:/project/user-app`; backend: `E:/xampp/htdocs/ba`.

Implemented the unified customer wallet, separate purchase/insurance balances, platform-configured offline/online deposits, insurance and purchase history, two-stage checkout totals, optional address details, Arabic translations and dark styling. Customer-facing seller navigation routes lead back to the platform; support uses platform tickets.

## Verified

- Flutter 3.47.2 / Dart 3.13.2: static analysis has no errors. Remaining analyzer warnings/style notices are not a clean-lint certification.
- `flutter test --no-pub`: 6 tests passed, including Arabic key coverage and server first-stage total parsing.
- `flutter build web --no-pub --no-wasm-dry-run --dart-define=BASE_URL=http://localhost/ba/public`: succeeded. This is a compilation check, not a browser runtime certification.
- Backend focused suite: 27 tests, 216 assertions passed (deposit identity/idempotency, wallet separation, offline second stage, invoice and refund contracts).
- Read-only wallet overview against local MySQL returned HTTP response status 200 and all expected sections. Routes require API authentication.

## Still requires device/environment verification

- Android SDK is not installed; no APK was built and no physical-device journey was exercised. iOS was not built on Windows.
- Local Apache was not listening on port 80 during verification. MySQL was started for the read-only smoke check.
- Emulator base URL defaults to `http://10.0.2.2/ba/public`. A physical phone requires `--dart-define=BASE_URL=<reachable backend URL>`.
- Production payment gateway credentials/callbacks and real transactions remain to be tested once the gateway is configured. No real customer balance was charged during validation.
- Verify release application identity, Firebase configuration, signing and map credentials before distribution. Existing Android release configuration uses the debug signing configuration.

Logs: `flutter-analysis.log`, `flutter-test.log`, `flutter-build-web.log`; backend: `storage/logs/customer-mobile-validation.txt`.
