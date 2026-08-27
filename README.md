# Behavior

Behavior is a behavioral-biometrics system with a Flutter dashboard and a Python/Flask backend. The system records mouse and keyboard interaction patterns, extracts measurable behavioral features, trains anomaly-detection models, and displays live trust indicators and historical information.

## Repository Status

The working project currently contains two directories:

- `twaq/`: the actual Flutter application and its native platform wrappers.
- `twayq/`: Python project metadata and the backend source files currently stored inside `__pycache__/`.

The Python files are real text source files, not normal compiled cache files, even though they are located in a directory normally reserved for Python bytecode. They import one another using top-level module names, so the backend should be launched from the directory containing those files, or the files should later be moved into a normal backend source directory. This README documents the current layout without changing it.

## System Overview

```text
Mouse events ───────> MouseAuthenticator ──┐
                                           ├──> Flask REST API ───> Flutter dashboard
Keyboard events ───> KeyboardAuthenticator ┘
                                               ├──> JSON data files
                                               └──> IsolationForest models
```

The backend collects input events with `pynput`. It divides the data into time windows, converts each window into numerical features, trains an `IsolationForest` model, and classifies later sessions as normal or anomalous. The Flutter app does not capture input directly; it calls the backend over HTTP and renders the returned JSON.

## Complete Repository Structure

```text
.
├── README.md
├── twaq/                                  # Flutter frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── analytics_page.dart
│   │   ├── history_page.dart
│   │   ├── settings_page.dart
│   │   └── custom_widgets.dart
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── analysis_options.yaml
│   ├── android/                            # Android host and Gradle files
│   ├── ios/                                # iOS Xcode host project
│   ├── linux/                              # Linux GTK/CMake host project
│   ├── macos/                              # macOS Xcode host project
│   ├── web/                                # Browser/PWA files
│   └── windows/                            # Windows Win32/CMake host project
└── twayq/                                  # Python backend project metadata
    ├── .idea/                              # PyCharm/IntelliJ settings
    └── __pycache__/                        # Current location of Python sources
        ├── backend_api.py
        ├── mouse_biometrics.py
        ├── keyboard_biometrics.py
        └── main.py
```

Generated build folders, `.venv`, binary icon assets, and `.pyc` files are not application source and are not described as logic below.

## Flutter Frontend Files

### `twaq/lib/main.dart`

This is the Flutter entry point and the main dashboard controller.

- `main()` starts `AdvancedBiometricApp`.
- `AdvancedBiometricApp` creates a dark Material application with `ProfessionalDashboard` as its home page.
- `_ProfessionalDashboardState` stores mouse match, keyboard match, overall trust, status text, monitoring state, and the selected sidebar page.
- A timer requests `GET http://127.0.0.1:5000/status` every 4 seconds.
- The response fields used are `mouse_perc`, `kb_perc`, `overall`, `status_msg`, and `is_monitoring`.
- `sendCommand()` sends `POST` requests for collection, training, and monitoring operations, then refreshes the status.
- The sidebar switches between dashboard, analytics, history, and settings.
- The logout icon calls `exit(0)` through `dart:io`.
- `WavyGraphPainter` draws two decorative filled paths behind the dashboard content.

Dashboard commands are `collect/start`, `collect/stop`, `train`, and `monitor/toggle`.

### `twaq/lib/analytics_page.dart`

`AnalyticsPage` displays historical behavioral metrics.

- Calls `GET /analytics` immediately and every 10 seconds.
- Converts `mouse_chart` and `kb_chart` arrays into `FlSpot` objects.
- Displays one line chart for mouse speed and one for keyboard activity.
- Reads `stats.avg_mouse_speed`, `stats.avg_angle`, `stats.avg_typing_speed`, and `stats.avg_dwell_time`.
- Uses `CustomLineChart` and `StatCard` from `custom_widgets.dart`.
- Provides a dropdown containing `Admin (الحالي)`, `User 1`, and `Guest`.

The dropdown currently changes local UI state only. It is not sent to Flask and does not filter the returned data.

### `twaq/lib/history_page.dart`

`HistoryPage` displays recent security-monitoring events.

- Calls `GET /history` immediately and every 3 seconds.
- Stores the returned array in `historyLogs`.
- Calculates the average `overall` value for the returned entries.
- Renders each entry with time, mouse percentage, keyboard percentage, and severity.
- Maps `عادية`, `متوسطة`, and other severity values to colors and icons.
- Shows an empty state when the backend returns no events.

Each history object is expected to contain `time`, `mouse`, `keyboard`, `overall`, and `severity`.

### `twaq/lib/settings_page.dart`

`SettingsPage` manages monitoring and client-side warnings.

- Reads the initial monitoring state from `GET /status`.
- Toggles the backend through `POST /monitor/toggle`.
- Updates the switch immediately and rolls it back when the request fails.
- Optionally checks security status every minute.
- Calculates `(mouse_perc + kb_perc) / 2` locally.
- Shows a warning when that average is below 50% while backend monitoring is active.
- Cancels the timer in `dispose()`.

The notification preference is held only in memory and is not persisted.

### `twaq/lib/custom_widgets.dart`

This file contains reusable presentation components and no backend logic.

- `CircularMetricCard`: colored circular percentage card used by the dashboard.
- `StatCard`: compact metric card with an icon, value, and unit.
- `SideMenuItem`: sidebar icon with active/inactive coloring.
- `ActionButton`: icon and label button used for backend commands.
- `CustomLineChart`: shared `fl_chart` line chart configuration.
- `SettingsSection`: styled grouping container for settings controls.

## Python Backend Files

### `twayq/__pycache__/mouse_biometrics.py`

Defines `MouseAuthenticator`, which records and analyzes mouse behavior.

#### Recording

- Uses `pynput.mouse.Listener` to capture movement, click, and scroll events.
- Stores timestamps, coordinates, event types, button names, press states, and scroll deltas in `current_session_data`.
- `start_recording()` prevents duplicate listeners and starts a new session.
- `stop_recording(save_to_file=True)` stops the listener and appends collected events to `mouse_data.json`.
- Existing JSON data is loaded before new events are appended.

#### Feature extraction

- `_extract_features()` sorts events by timestamp and groups them into 2-second windows.
- Windows with six or fewer events are ignored.
- `_analyze_chunk()` calculates five features per window:
  1. Average movement speed.
  2. Standard deviation of movement speed.
  3. Average acceleration.
  4. Click count.
  5. Scroll count.
- Speed is calculated as distance divided by elapsed time.
- Acceleration is calculated as the change in speed divided by elapsed time.

#### Training and verification

- `train_model()` requires `mouse_data.json` and at least 10 extracted samples.
- Trains an `IsolationForest` with 500 estimators, 10% contamination, and `random_state=42`.
- Saves the model to `mouse_model.pkl` with `joblib`.
- `verify_current_session(threshold=70.0)` predicts each current feature window and returns a match percentage based on predictions classified as normal (`1`).
- A session is considered authorized when its match percentage is at least the threshold.

### `twayq/__pycache__/keyboard_biometrics.py`

Defines `KeyboardAuthenticator`, which records and analyzes keyboard behavior.

#### Recording

- Uses `pynput.keyboard.Listener` to capture key press and release events.
- Stores timestamp, action (`press` or `release`), and a normalized key name.
- Supports regular characters and special keys.
- `start_recording()` starts a clean session and prevents duplicate listeners.
- `stop_recording(save_to_file=True)` appends events to `keyboard_data.json`.

#### Feature extraction

- `_extract_features()` sorts events and groups them into 5-second windows.
- Windows with three or fewer events are ignored.
- `_analyze_chunk()` calculates:
  1. Average dwell time, from press to release for the same key.
  2. Average flight time, from the previous release to the next press.
  3. Keystroke count.
- Pauses longer than 2 seconds are excluded from flight-time calculations.
- Dwell times longer than 2 seconds are excluded.

#### Training and verification

- `train_model()` requires `keyboard_data.json` and at least five extracted samples.
- Trains an `IsolationForest` with `contamination=0.1` and `random_state=42`.
- Saves the model to `keyboard_model.pkl`.
- `verify_current_session(threshold=70.0)` converts predictions classified as normal into a match percentage and compares it with the threshold.

### `twayq/__pycache__/backend_api.py`

Creates and runs the Flask REST service.

#### Global state

- Creates `MouseAuthenticator` and `KeyboardAuthenticator` instances.
- Maintains `status_data` with mouse percentage, keyboard percentage, overall score, status message, monitoring state, and collection state.
- Maintains 20-item live history arrays and an in-memory list of up to 100 monitoring logs.
- Enables CORS with `flask_cors.CORS(app)`.

#### `normalize_percentage()`

Converts a value to a float, clamps it to 0-100, rounds to two decimal places, and returns `0.0` for invalid values.

#### `monitoring_loop()`

Runs in a daemon thread while monitoring is enabled.

- Starts both recorders.
- Collects events for 4 seconds in 0.1-second intervals.
- Treats a device as active when its session contains more than two events.
- Stops recording without saving the monitoring window.
- Verifies mouse and keyboard sessions using a 70% threshold.
- Uses the active device score when only one device has activity.
- When both devices are active, uses the higher score as `overall` and marks the lower score as a warning when it is below 50%.
- Updates live status and keeps the last 20 score values in memory.
- Adds active windows to the history list and caps it at 100 entries.

#### Flask routes

| Method | Route | Behavior |
| --- | --- | --- |
| `GET` | `/status` | Returns the complete `status_data` object. |
| `POST` | `/collect/start` | Sets collection active and starts both recorders. |
| `POST` | `/collect/stop` | Stops both recorders and saves their events to JSON files. |
| `POST` | `/train` | Trains both anomaly-detection models and returns their messages. |
| `POST` | `/monitor/toggle` | Starts or stops the monitoring thread and resets scores on stop. |
| `GET` | `/history` | Returns the in-memory monitoring history list. |
| `GET` | `/analytics` | Reads saved JSON data, extracts features, computes charts and averages, and returns them. |

The `/analytics` route calculates mouse speed and angle statistics from `mouse_data.json`, and keyboard typing speed and dwell time from `keyboard_data.json`. Chart arrays are limited to the latest 50 values.

The backend starts with `debug=False` on port `5000` when `backend_api.py` is executed directly.

### `twayq/__pycache__/main.py`

Provides a command-line backend runner independent of Flask.

It creates both authenticators and offers three interactive modes:

1. **Collection mode:** records mouse and keyboard input in five-minute cycles and saves each cycle automatically. `Ctrl+C` stops and saves the current session.
2. **Training mode:** trains both models and prints their result messages.
3. **Monitoring mode:** records five-second windows, verifies both signatures using a 70% threshold, chooses the stronger score when both devices are active, and prints a timestamped security status. `Ctrl+C` stops the loop.

This file is a standalone console alternative to the Flask API. The Flutter application does not call it directly.

## `twayq/.idea/` Metadata

These files configure the Python IDE and do not implement application behavior.

- `.idea/misc.xml`: selects a Python 3.11 SDK and Black formatter integration.
- `.idea/modules.xml`: registers the IDE module.
- `.idea/twayq.iml`: declares a Python module and excludes `.venv`.
- `.idea/workspace.xml`: local workspace layout and IDE state.
- `.idea/inspectionProfiles/Project_Default.xml`: project inspection profile.
- `.idea/inspectionProfiles/profiles_settings.xml`: inspection-profile settings.
- `.idea/.gitignore`: excludes additional local IDE files.

## Flutter Platform Files

The native directories are host wrappers around the Dart application. They do not contain the biometric analysis.

### Android

`android/settings.gradle.kts` loads Flutter's Gradle plugins and includes the app module. `android/build.gradle.kts` configures repositories, build-directory relocation, and cleaning. `android/app/build.gradle.kts` defines the Android module, Java/Kotlin 17, namespace and application ID `com.example.twaq`, Flutter SDK values, and build types. `MainActivity.kt` hosts Flutter, the manifests define Android application and launcher metadata, resource XML files define launch themes, and Gradle wrapper files define the Gradle distribution.

### iOS

`ios/Runner/AppDelegate.swift` starts the native iOS application. `Info.plist` defines bundle metadata, orientations, launch configuration, and input support. Storyboards define launch and main resources, `Assets.xcassets` contains icons and launch assets, Xcode project/workspace files define native targets, and Flutter xcconfig files provide build settings. `RunnerTests.swift` is the native test placeholder.

### macOS

`macos/Runner/AppDelegate.swift` is the application delegate and `MainFlutterWindow.swift` creates the Flutter window. `Info.plist`, `MainMenu.xib`, xcconfig files, entitlements, asset catalogs, Xcode project/workspace files, generated plugin registration, and the native test target provide macOS packaging and build integration.

### Linux

`linux/CMakeLists.txt` configures the GTK application, binary name `twaq`, application ID `com.example.twaq`, C++14 settings, dependencies, and installation bundle. The runner sources create a GTK window and attach the Flutter view. Files under `linux/flutter/` connect CMake to Flutter's generated engine and plugin build; generated files should not be edited manually.

### Windows

`windows/CMakeLists.txt` configures the Windows build, C++17 settings, Flutter engine, packaging, and executable name `twaq`. `runner/main.cpp` initializes COM, creates a 1280x720 Flutter window, and runs the Win32 message loop. `flutter_window.*` manages the Flutter controller, `win32_window.*` handles the native window and DPI behavior, and `utils.*` manages console output and command-line conversion. Resource files define the icon, manifest, and Windows identifiers. Flutter plugin files are generated and currently contain no registered plugins.

### Web

`web/index.html` is the browser entry document and Flutter bootstrap page. `manifest.json` defines PWA metadata, theme colors, orientation, and icons. The web client still uses the configured local API address, so browser access and Flask CORS configuration are required.

## Dependencies

### Flutter

The Flutter project requires Dart `^3.10.7` and declares `fl_chart` for charts, `http` for API calls, `flutter_lints` for analysis, and `flutter_test` for tests. The current `pubspec.yaml` places `http` under `dev_dependencies` even though runtime files import it; it should normally be a regular dependency.

### Python

The backend imports:

- `Flask` and `flask-cors` for the REST service and cross-origin requests.
- `pynput` for mouse and keyboard event listeners.
- `numpy` for mouse statistics.
- `scikit-learn` for `IsolationForest`.
- `joblib` for model serialization.

No `requirements.txt` is currently present, so the exact pinned Python versions are not defined by the repository.

## Installation and Running

### Flutter frontend

```powershell
cd twaq
flutter pub get
flutter devices
flutter run -d windows
```

Replace `windows` with a device identifier returned by `flutter devices`. Build Windows with:

```powershell
flutter build windows
```

### Flask backend

Because the current Python source files are inside `twayq/__pycache__/`, run from that directory for the current layout:

```powershell
cd twayq\__pycache__
python -m venv ..\.venv
..\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install Flask flask-cors pynput numpy scikit-learn joblib
python backend_api.py
```

The service listens on `http://127.0.0.1:5000`.

Before monitoring, use `POST /collect/start` to gather enough data, `POST /collect/stop` to save it, and `POST /train` to create `mouse_model.pkl` and `keyboard_model.pkl`. The backend needs sufficient samples: at least 10 mouse feature windows and at least 5 keyboard feature windows.

### Connecting Flutter to Flask

1. Start Flask on port `5000`.
2. Verify `GET http://127.0.0.1:5000/status` returns HTTP 200.
3. Start Flutter.
4. Use the dashboard controls to collect data, stop and save it, train models, and enable monitoring.

PowerShell health check:

```powershell
Invoke-RestMethod http://127.0.0.1:5000/status
```

On an Android emulator, `127.0.0.1` normally points to the emulator itself; use `10.0.2.2` for the host machine. On a physical device, use the computer's LAN IP and configure Flask/firewall access. For web builds, configure Flask CORS and use an address reachable by the browser.

## Generated and Runtime Files

When the backend runs, it may create:

- `mouse_data.json`: recorded mouse events.
- `keyboard_data.json`: recorded keyboard events.
- `mouse_model.pkl`: trained mouse `IsolationForest`.
- `keyboard_model.pkl`: trained keyboard `IsolationForest`.

These files can contain sensitive behavioral and input metadata. Protect them appropriately and do not commit them to a public repository.

## Validation

Run the Flutter checks from `twaq/`:

```powershell
cd twaq
flutter analyze
flutter test
```

For the backend, verify imports and route availability from the directory containing the Python sources:

```powershell
python -m py_compile backend_api.py mouse_biometrics.py keyboard_biometrics.py main.py
```

## Known Limitations

- Python source files are currently stored under `__pycache__/`, which is unconventional and may be ignored by Git tooling.
- No Python dependency manifest is present.
- The client repeats the API base URL in several Dart files.
- The Flutter package and native identifiers still use `twaq`; this README uses the product name **Behavior** without changing code.
- The analytics user selector is not connected to backend filtering.
- The notification preference is not persisted.
- The backend stores state in memory and local JSON/model files rather than a database.
- The monitoring thread and shared state have no explicit synchronization mechanism.
- No license file is included.