# Grading App — Offline-First SQLite + Firebase Sync

This Flutter app uses a **local-first** data layer: todos are always saved to **SQLite** first, then synced to **Firebase Firestore** when the device is online. If the user is offline, changes stay in SQLite and are pushed automatically once connectivity returns.

---

## How This System Was Built

### Architecture Overview

```
┌─────────────┐     write first      ┌──────────────────┐
│   UI Layer  │ ──────────────────►  │  TodoProvider    │
│  (Screens)  │                      │  (State + Sync)  │
└─────────────┘                      └────────┬─────────┘
                                              │
                         ┌────────────────────┼────────────────────┐
                         ▼                    ▼                    ▼
                 ┌───────────────┐    ┌──────────────┐    ┌─────────────────┐
                 │ DatabaseHelper│    │  TodoService │    │ Firestore Stream│
                 │   (SQLite)    │    │  (Firebase)  │    │  (Remote Pull)  │
                 └───────────────┘    └──────────────┘    └─────────────────┘
                         │                    │                    │
                         ▼                    ▼                    ▼
                   grading_app.db      users/{uid}/todos     Real-time updates


### Core Idea: Write Local, Sync Remote

Every create, update, or delete follows the same pattern:

1. Save to SQLite immediately** — the UI updates right away, even with no internet.
2. Mark the row as unsynced** (`isSynced = 0`).
3. Try to sync to Firestore** if online.
4. if sync fails or user is offline**, background job retries every 15 seconds.

### SQLite Layer (`lib/services/database_helper.dart`)

- Package: `sqflite` + `path`
- Database file: `grading_app.db` (created automatically on the device)
- Table: `todos`

| Column       | Purpose                                      |
|-------------|----------------------------------------------|
| `todoId`    | Primary key (matches Firestore document ID)  |
| `title`, `description`, `category`, `priority`, `dueDate`, `isCompleted`, `createdAt`, `updatedAt` | Task data |
| `userId`    | Owner of the todo                            |
| `isSynced`  | `0` = pending upload, `1` = synced         |
| `isDeleted` | `0` = active, `1` = soft-deleted pending sync |

### Firebase Layer (`lib/services/todo_service.dart`)

- Auth Firebase Authentication (email/password) via `AuthService`
- Database* Cloud Firestore
- Collection path**: `users/{userId}/todos/{todoId}`


### Sync Logic (`lib/providers/todo_provider.dart`)

Three sync paths work together:

#### 1. Immediate sync (on every write)

After add/update/delete, the provider checks connectivity and pushes to Firestore right away. On success, it calls `markAsSynced()`.

#### 2. Background sync (every 15 seconds)

A `Timer.periodic` runs `syncUnsyncedData()`:

- Skips if offline or already syncing
- Loads all rows where `isSynced = 0`
- For deleted rows (`isDeleted = 1`): delete from Firestore, then remove from SQLite
- For active rows: upload to Firestore, then `markAsSynced()`

#### 3. Remote merge (Firestore stream)

When Firestore sends updates:

- **Local unsynced changes win** — remote data does not overwrite rows with `isSynced = 0`
- **Synced local data is updated** from Firestore
- **Items deleted on Firestore** are removed locally only if they were already synced

### Conflict Rules

| Scenario                         | Winner              |
|----------------------------------|---------------------|
| Local change not yet synced      | Local               |
| Local synced, remote updated     | Remote (Firestore)  |
| Deleted locally, pending sync    | Local deletion wins |
| Deleted on Firestore, synced locally | Remove from SQLite |

### App Initialization (`lib/main.dart`)

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const MyApp());
```

When a user logs in, `TodoProvider.initialize(userId)`:

1. Loads todos from SQLite
2. Subscribes to the Firestore stream
3. Starts the 15-second sync timer

---

## Commands: Connect Firebase

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (for Firebase CLI)
- A Firebase project at [Firebase Console](https://console.firebase.google.com/)

### Step 1 — Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Step 2 — Log in to Firebase

```bash
firebase login
```

### Step 3 — Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Make sure `$HOME/.pub-cache/bin` (or `%LOCALAPPDATA%\Pub\Cache\bin` on Windows) is on your PATH.

### Step 4 — Configure Firebase for this Flutter project

From the project root:

```bash
cd c:/petergwapo/Flutter_Project/grading_app
flutterfire configure
```

This command:

- Links the app to your Firebase project (`andresgradingsystem` in this repo)
- Generates `lib/firebase_options.dart`
- Downloads `android/app/google-services.json` (Android)
- Updates `firebase.json`

### Step 5 — Add Firebase packages

```bash
flutter pub add firebase_core firebase_auth cloud_firestore
```

### Step 6 — Enable services in Firebase Console

1. **Authentication** → Sign-in method → enable **Email/Password**
2. **Firestore Database** → Create database (test or production mode)
3. Add security rules (example for authenticated users):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Step 7 — Initialize Firebase in code

Already done in `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Step 8 — Run the app

```bash
flutter pub get
flutter run
```

---

## Commands: Connect SQLite

SQLite in Flutter does **not** use a separate server or connection string. The `sqflite` plugin creates and opens a file on the device automatically.

### Step 1 — Add dependencies

```bash
flutter pub add sqflite path
```

### Step 2 — Database is opened on first use

In `DatabaseHelper`, the database path is resolved at runtime:

```dart
final dbPath = await getDatabasesPath();
final path = join(dbPath, 'grading_app.db');

return await openDatabase(
  path,
  version: 1,
  onCreate: _createDB,
);
```

No manual `sqlite3` CLI connection is required for the app to work.

### Step 3 — Inspect SQLite during development (optional)

**Android (device/emulator):**

```bash
adb shell
run-as com.example.grading_app
cd databases
ls
sqlite3 grading_app.db
.tables
SELECT todoId, title, isSynced, isDeleted FROM todos;
.quit
```

**Using Android Studio:** Device File Explorer → `data/data/com.example.grading_app/databases/grading_app.db` → pull file and open with [DB Browser for SQLite](https://sqlitebrowser.org/).

**iOS Simulator:**

```bash
xcrun simctl get_app_container booted com.example.grading_app data
# Then browse to Library/Application Support/databases/grading_app.db
```

---

## Project Structure (Sync-Related Files)

```
lib/
├── main.dart                    # Firebase init + Provider setup
├── firebase_options.dart        # Generated by flutterfire configure
├── models/
│   └── todo_model.dart          # Shared model (Firestore + SQLite)
├── services/
│   ├── database_helper.dart     # SQLite CRUD + sync flags
│   ├── todo_service.dart        # Firestore CRUD + connectivity
│   └── auth_service.dart        # Firebase Auth
└── providers/
    └── todo_provider.dart       # Local-first logic + sync engine
```

---

## AI Prompt: How to Build This System

Copy and paste the prompt below into an AI assistant to recreate or extend this offline-first pattern:

```
Build an offline-first Flutter todo app with SQLite local storage and Firebase Firestore sync.

Requirements:

1. LOCAL-FIRST WRITES
   - Every add, update, and delete must save to SQLite first so the UI works offline.
   - Use sqflite with a todos table that includes isSynced (0/1) and isDeleted (0/1) columns.

2. FIREBASE REMOTE STORAGE
   - Use firebase_core, firebase_auth, and cloud_firestore.
   - Store todos at: users/{userId}/todos/{todoId}
   - Initialize Firebase with DefaultFirebaseOptions from flutterfire configure.

3. SYNC ENGINE (TodoProvider)
   - On initialize(userId): load SQLite, subscribe to Firestore stream, start a Timer.periodic every 15 seconds.
   - syncUnsyncedData(): if online, upload all rows where isSynced = 0.
     - isDeleted = 1 → delete from Firestore, then delete row from SQLite.
     - isDeleted = 0 → set/add to Firestore, then markAsSynced().
   - After each local write, attempt immediate sync if online.

4. MERGE RULES (Firestore → SQLite)
   - Do not overwrite local rows where isSynced = 0 (local wins).
   - Overwrite synced local rows with Firestore data.
   - If a synced local todo is missing from Firestore, delete it locally.

5. CONNECTIVITY
   - Use InternetAddress.lookup('google.com') to detect online status before syncing.

6. DELETE BEHAVIOR
   - If a todo was never synced (isSynced = 0), delete permanently from SQLite only.
   - If synced, soft-delete locally (isDeleted = 1, isSynced = 0) and sync deletion to Firestore.

7. ARCHITECTURE
   - DatabaseHelper (singleton) for SQLite
   - TodoService for Firestore operations
   - TodoProvider (ChangeNotifier) for state + sync
   - Provider package for dependency injection

8. SETUP COMMANDS
   - firebase login
   - dart pub global activate flutterfire_cli
   - flutterfire configure
   - flutter pub add sqflite path firebase_core firebase_auth cloud_firestore provider

Generate: database_helper.dart, todo_service.dart, todo_provider.dart, todo_model.dart, and main.dart with Firebase.initializeApp().
```

---

## Dependencies

| Package            | Role                          |
|--------------------|-------------------------------|
| `sqflite`          | Local SQLite database         |
| `path`             | Database file path helper     |
| `firebase_core`    | Firebase initialization       |
| `firebase_auth`    | User authentication           |
| `cloud_firestore`  | Remote todo storage           |
| `provider`         | State management              |

---

## Testing Offline Sync

1. Run the app and log in.
2. Turn off Wi‑Fi / mobile data (or use airplane mode).
3. Add, edit, or delete todos — they should appear instantly (saved in SQLite).
4. Turn internet back on.
5. Within ~15 seconds (or immediately on the next write), todos sync to Firestore.
6. Verify in Firebase Console → Firestore → `users/{uid}/todos`.

---

## Firebase Project Info (This Repo)

| Setting    | Value                 |
|-----------|------------------------|
| Project ID | `andresgradingsystem` |
| Config file | `lib/firebase_options.dart` |
| Android config | `android/app/google-services.json` |

Regenerate config anytime with:

```bash
flutterfire configure
```
