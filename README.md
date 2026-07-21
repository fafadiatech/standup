# standup — Frappe + Flutter Monorepo

A Frappe/ERPNext custom app and Flutter mobile client living in a single repository.

## Repository Layout

```
standup/                          ← repo root (valid Frappe app)
│
├── pyproject.toml                ← Python package config; excludes /app
├── MANIFEST.in                   ← sdist manifest; prunes /app
├── requirements.txt              ← Frappe Python deps (bench setup requirements)
├── .gitignore
│
├── standup/                      ← Frappe app Python package
│   ├── __init__.py               ← __version__
│   ├── hooks.py                  ← app metadata, doc events, scheduler, CORS
│   ├── modules.txt
│   ├── patches.txt
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   └── auth.py               ← mobile_login / logout / me / refresh_token
│   │
│   ├── config/
│   │   ├── __init__.py
│   │   └── desktop.py
│   │
│   ├── standup/                  ← Frappe module (doctypes live here)
│   │   └── doctype/
│   │
│   ├── public/js/
│   ├── templates/
│   └── www/
│
├── app/                          ← Flutter mobile client (fully isolated)
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/
│   │   │   ├── frappe_api_service.dart   ← Dio client + auth interceptor
│   │   │   └── auth_service.dart         ← Riverpod auth state
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── home_screen.dart
│   ├── test/
│   │   └── frappe_api_service_test.dart
│   ├── android/
│   └── ios/
│
└── .github/
    └── workflows/
        ├── frappe-tests.yml      ← CI: bench install + run-tests + ruff
        └── flutter-tests.yml     ← CI: flutter test + android build
```

---

## Quick Start

### A. Frappe / Bench Side

#### Prerequisites
- Python ≥ 3.10
- [bench CLI](https://frappeframework.com/docs/user/en/installation)
- MariaDB 10.6+ or PostgreSQL 13+
- Node.js 18+ & npm (for Frappe asset builds)
- Redis

#### 1. Initialise a Bench (skip if you already have one)

```bash
bench init frappe-bench --frappe-branch version-15
cd frappe-bench
bench new-site standup.localhost \
  --db-root-password <your-root-pw> \
  --admin-password admin
```

#### 2. Install the app from git

```bash
bench get-app standup https://github.com/fafadiatech/standup
bench --site standup.localhost install-app standup
```

**The `/app` Flutter folder is never touched by Bench** — `pyproject.toml` and
`MANIFEST.in` both exclude it explicitly.

#### 3. Start the development server

```bash
bench start        # starts gunicorn + workers + scheduler + file-watcher
```

Frappe is now available at `http://standup.localhost:8000`.

#### 4. Enable developer mode (hot-reload for Python changes)

```bash
bench --site standup.localhost set-config developer_mode 1
bench --site standup.localhost clear-cache
```

#### 5. Run Frappe tests

```bash
bench --site standup.localhost run-tests --app standup
```

---

### B. Flutter Side

#### Prerequisites
- Flutter SDK ≥ 3.22 (stable channel)
- Android Studio / Xcode for device simulators

#### 1. Install dependencies

```bash
cd app
flutter pub get
```

#### 2. Point to your local Frappe instance

Edit `lib/services/frappe_api_service.dart`:

```dart
const String _kBaseUrl = 'http://10.0.2.2:8000'; // Android emulator
// const String _kBaseUrl = 'http://localhost:8000'; // iOS simulator / web
```

> **Android emulator** maps `10.0.2.2` to the host machine's localhost.
> For a real device on the same Wi-Fi, use your machine's LAN IP.

#### 3. Run

```bash
cd app
flutter run          # picks up a connected device or simulator
flutter run -d chrome  # web target (Frappe must have CORS configured)
```

#### 4. Test

```bash
cd app
flutter test
flutter test --coverage   # generates coverage/lcov.info
```

#### 5. Build release artifacts

```bash
cd app
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
flutter build ipa --release          # iOS (requires macOS + Xcode)
```

---

## Authentication Flow

```
Flutter                              Frappe
  │                                     │
  │── POST /api/method/standup.          │
  │   api.auth.mobile_login             │
  │   { usr, pwd }  ─────────────────► │
  │                                     │── validate credentials
  │                                     │── generate / return api_key + api_secret
  │ ◄──────────────────────────────── { │
  │   api_key, api_secret, user }       │
  │                                     │
  │   [store in flutter_secure_storage] │
  │                                     │
  │── GET /api/resource/StandupEntry    │
  │   Authorization: token key:secret ► │
  │                                     │── token auth (no CSRF check)
  │ ◄────────────────────── { data: [] }│
```

### CORS (development)

`hooks.py` sets `allow_cors = "*"` for development convenience.
For production, restrict this to your app's domain or distribution URL:

```python
allow_cors = "https://standup.yourdomain.com"
```

---

## CI / CD

| Workflow             | Triggers on                          | What it does                              |
|----------------------|--------------------------------------|-------------------------------------------|
| `frappe-tests.yml`   | Push / PR touching `standup/**`      | bench init → install-app → run-tests → ruff lint |
| `flutter-tests.yml`  | Push / PR touching `app/**`          | flutter test → flutter build apk          |

The two pipelines are deliberately independent — a Flutter-only change never
triggers Frappe CI and vice-versa.

---

## Environment Variables / Secrets

| Secret name (GitHub)       | Used by                | Description                            |
|----------------------------|------------------------|----------------------------------------|
| `FRAPPE_BASE_URL`          | Flutter (--dart-define)| Production API base URL                |
| `ANDROID_KEYSTORE_BASE64`  | flutter-tests.yml      | Base64-encoded release keystore        |
| `ANDROID_KEY_ALIAS`        | flutter-tests.yml      | Key alias                              |
| `ANDROID_KEY_PASSWORD`     | flutter-tests.yml      | Key password                           |

Pass `--dart-define` values at build time:

```bash
flutter build apk --release \
  --dart-define=FRAPPE_BASE_URL=https://erp.yourdomain.com
```

Then read in Dart:

```dart
const String _kBaseUrl =
    String.fromEnvironment('FRAPPE_BASE_URL', defaultValue: 'http://localhost:8000');
```
