# Standup — Mobile App

Standup gives your workforce real-time access to ERPNext from the palm of their hand. Built on Flutter for maximum speed and smooth usability across iOS and Android, Standup eliminates operational lag, speeds up approvals, and drives organization-wide efficiency.

---

## Features

| Module | Capabilities |
|---|---|
| **Authentication** | Token-based login, session restoration on launch |
| **Home** | Weekly meetings, upcoming events, birthdays, work anniversaries, achievements |
| **Tasks** | View tasks, create tasks (API integrated), update status, log time manually |
| **Leave** | Check leave balance, view history, apply for leave |
| **Pantry** | Browse snack catalog, raise snack requests, staff approval workflow |
| **Leaderboard** | Company leaderboard, employee of the month |
| **Profile** | User profile details |
| **Notifications** | In-app notification centre |

Role-based routing: pantry staff are redirected to the Pantry Dashboard instead of the standard Home screen.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart 3.12+) |
| State Management | Riverpod 2.x (`StateNotifier` + providers) |
| Navigation | GoRouter 14.x |
| HTTP Client | `http` package |
| Secure Storage | `flutter_secure_storage` |
| Internationalisation | `intl` |
| Backend | ERPNext v15 + Frappe Framework + HRMS |
| Auth Scheme | API Key + API Secret (token auth) |

---

## Backend Setup

The backend runs via Docker Compose (Frappe + ERPNext + HRMS + the `standup` Frappe app).

### Start the server

```bash
# First run — build images and create site
docker compose up --build -d
docker compose run --rm create-site

# Subsequent runs
docker compose up -d
```

Apps installed on the site: `erpnext`, `hrms`, `standup`.

Default credentials: `administrator` / `admin`

### Android emulator connection

The app points to `http://10.0.2.2:8080` by default, which is how the Android emulator reaches the host machine. The Frappe `Host` header is set to `site1.localhost` to match the site name configured in `docker-compose.yaml`.

For a physical device or staging server, update both values in:

```
lib/core/constants/api_constants.dart
```

```dart
static const String baseUrl = 'http://<your-server-ip>:8080';
static const String frappeSiteName = '<your-site-name>';
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # API endpoint constants
│   ├── services/        # HTTP service layer (auth, tasks, leave, pantry…)
│   ├── theme/           # Colours, text styles
│   └── router/          # GoRouter config with role-based redirects
├── data/
│   ├── models/          # Dart model classes (TaskModel, LeaveModel…)
│   └── mock/            # Mock data for local development
└── features/
    ├── auth/
    ├── home/
    ├── task/
    ├── leave/
    ├── snack/
    ├── board/
    ├── profile/
    └── notifications/
```

---

## API Integration Status

| Endpoint group | Status |
|---|---|
| Authentication | Integrated |
| Home (meetings, events, birthdays) | Integrated |
| Tasks — fetch | Integrated |
| Tasks — create | Integrated |
| Tasks — update status | Integrated |
| Leave — fetch & apply | Integrated |
| Pantry — full CRUD + workflow | Integrated |
| Achievements | Integrated |
| Leaderboard / Employee of the Month | Integrated |
