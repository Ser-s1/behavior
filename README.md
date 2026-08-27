# Behavior

Behavior is a Flutter dashboard for behavioral biometrics. It displays mouse and keyboard behavior scores, trust levels, analytics, monitoring history, and security notifications. The Flutter client is designed to communicate with a Python/Flask REST API.

> **Repository status:** This repository currently contains the Flutter client and its API call sites. It does not contain the Python/Flask implementation, `backend_api.py`, or `requirements.txt`. The backend must be supplied separately before the complete system can run end to end.

## Overview

The application treats mouse and keyboard interaction patterns as a behavioral signature. The backend is expected to collect input events, extract behavioral features, analyze them, and return biometric indicators. Flutter renders those results in a security dashboard; it does not collect input events itself.

The client provides four views:

- **Dashboard:** live mouse match, keyboard match, overall trust, connection status, and system controls.
- **Analytics:** historical mouse-speed and typing-intensity charts and biometric averages.
- **History:** recent monitoring events, severity, individual scores, and session average.
- **Settings:** live-monitoring control and periodic security notifications.

## Architecture

```text
Flutter client (twaq/lib/*.dart)
        | HTTP/JSON on port 5000
        v
Python/Flask backend (not included in this repository)
        |
        +-- input-event collection
        +-- feature extraction and analysis
        +-- training
        +-- live monitoring and history
```

The client currently uses `http://127.0.0.1:5000` as a fixed base URL. Each page contains its own request code, so changing the address currently requires changes in multiple Dart files.

## Repository Structure

```text
.
├── README.md
├── twaq/                              # Actual Flutter application
│   ├── lib/
│   │   ├── main.dart                  # Entry point and dashboard
│   │   ├── analytics_page.dart        # Analytics and charts
│   │   ├── history_page.dart          # Monitoring history
│   │   ├── settings_page.dart         # Settings and alerts
│   │   └── custom_widgets.dart        # Shared UI widgets
│   ├── pubspec.yaml                   # Flutter package manifest
│   ├── pubspec.lock                   # Resolved Dart versions
│   ├── analysis_options.yaml          # Lint configuration
│   ├── android/                       # Android host project
│   ├── ios/                           # iOS host project
│   ├── linux/                         # Linux host project
│   ├── macos/                         # macOS host project
│   ├── web/                           # Web entry point and PWA files
│   └── windows/                       # Windows host project
└── twayq/                             # IDE metadata only
    └── .idea/                         # PyCharm/IntelliJ settings
```

## Detailed File Guide

### Application Source: `twaq/lib/`

#### `main.dart`

The Flutter entry point. It launches the app, configures the dark Material theme, creates the dashboard, stores live biometric values, polls `GET /status` every 4 seconds, and sends control commands. It also builds the sidebar navigation and switches between the four application views. `WavyGraphPainter` draws the decorative dashboard background, while `dart:io` is used to exit the application from the logout icon.

#### `analytics_page.dart`

Implements `AnalyticsPage`. It requests `GET /analytics` on startup and every 10 seconds. It converts `mouse_chart` and `kb_chart` arrays into `FlSpot` values for `fl_chart`, then reads `stats` values for average mouse speed, movement angle, typing speed, and key dwell time. The user dropdown is local UI state only; the selected user is not sent to the backend.

#### `history_page.dart`

Implements `HistoryPage`. It requests `GET /history` on startup and every 3 seconds, stores the returned log array, calculates the average `overall` value, and renders event cards. Each event is expected to contain `time`, `mouse`, `keyboard`, `overall`, and `severity`. Severity values are mapped to colors and icons.

#### `settings_page.dart`

Implements `SettingsPage`. It reads monitoring state from `GET /status`, toggles monitoring through `POST /monitor/toggle`, and rolls the switch back if the request fails. An optional timer checks the status every minute and displays a warning when the average of `mouse_perc` and `kb_perc` is below 50% while monitoring is active. Timers are cancelled when the page is disposed.

#### `custom_widgets.dart`

Contains presentation-only reusable widgets: `CircularMetricCard`, `StatCard`, `SideMenuItem`, `ActionButton`, `CustomLineChart`, and `SettingsSection`. These widgets do not call the backend and do not perform biometric analysis.

### Flutter Configuration

#### `pubspec.yaml`

Defines the Flutter package as `twaq`, version `0.1.0`, with Dart constraint `^3.10.7`. It declares Flutter, `fl_chart`, `flutter_test`, `flutter_lints`, and `http`. The `http` package is currently under `dev_dependencies` even though runtime application files import it; it should normally be under `dependencies`.

#### `pubspec.lock`

Generated lockfile containing resolved direct and transitive Dart package versions. It should be regenerated by Flutter tooling rather than edited manually.

#### `analysis_options.yaml`

Enables the standard lint rules from `package:flutter_lints/flutter.yaml`.

#### `.gitignore`, `.metadata`, `.vscode/settings.json`, and the nested `README.md`

These are project metadata and tooling files. `.gitignore` excludes generated output, `.metadata` stores Flutter tooling metadata, `.vscode/settings.json` stores a local CMake path, and the nested README is the default Flutter placeholder. The root README is the authoritative documentation.

## Platform Files

### Android: `twaq/android/`

- `settings.gradle.kts` loads Flutter's Gradle build, declares Android/Kotlin plugin versions, and includes the `app` module.
- `build.gradle.kts` configures repositories, relocates the build directory, and defines the clean task.
- `app/build.gradle.kts` configures namespace and application ID `com.example.twaq`, Java/Kotlin 17, Flutter SDK values, and build types.
- `app/src/main/kotlin/com/example/twaq/MainActivity.kt` hosts the Flutter engine in the native Android activity.
- `app/src/main/AndroidManifest.xml` declares the application, launcher activity, Flutter embedding, and Android queries.
- `app/src/debug/AndroidManifest.xml` and `app/src/profile/AndroidManifest.xml` provide debug/profile manifest overlays.
- `app/src/main/res/drawable*/launch_background.xml` define launch backgrounds for supported API levels.
- `app/src/main/res/values*/styles.xml` define normal and night launch themes.
- `gradle.properties` and `gradle/wrapper/gradle-wrapper.properties` configure Gradle behavior and the wrapper distribution.

### iOS: `twaq/ios/`

- `Runner/AppDelegate.swift` starts the iOS application and Flutter integration.
- `Runner/Info.plist` defines bundle metadata, supported orientations, launch storyboard, and input support.
- `Runner/Runner-Bridging-Header.h` provides Swift/Objective-C interoperability.
- `Runner/Base.lproj/*.storyboard` define the launch and main storyboard resources.
- `Runner/Assets.xcassets/` contains application icon and launch assets.
- `Runner.xcodeproj/` and `Runner.xcworkspace/` contain Xcode project and workspace definitions.
- `Flutter/*.xcconfig` and `AppFrameworkInfo.plist` provide Flutter build configuration and framework metadata.
- `RunnerTests/RunnerTests.swift` is the native iOS test target placeholder.

### macOS: `twaq/macos/`

- `Runner/AppDelegate.swift` is the macOS application delegate.
- `Runner/MainFlutterWindow.swift` creates the native window that hosts Flutter.
- `Runner/Info.plist` contains macOS bundle metadata.
- `Runner/Base.lproj/MainMenu.xib` defines the native menu and window resource.
- `Runner/Configs/*.xcconfig` contain application, debug, release, and warning settings.
- `Runner/*entitlements` declare capabilities for debug/profile and release builds.
- `Runner/Assets.xcassets/` contains macOS icons.
- `Runner.xcodeproj/`, `Runner.xcworkspace/`, and `Flutter/*` provide Xcode and Flutter build metadata.
- `RunnerTests/RunnerTests.swift` is the native macOS test target placeholder.

### Linux: `twaq/linux/`

- `CMakeLists.txt` configures the GTK application, binary name `twaq`, application ID `com.example.twaq`, GTK dependencies, installation bundle, and C++14 settings.
- `runner/CMakeLists.txt` configures the native Linux runner target.
- `runner/main.cc` creates `MyApplication` and starts the GTK application loop.
- `runner/my_application.h` and `my_application.cc` define the GTK application, create a 1280x720 Flutter window, attach the Flutter view, and register plugins.
- `flutter/CMakeLists.txt` connects CMake to Flutter's Linux engine and tool backend; it is tool-managed.
- `flutter/generated_plugin_registrant.*` and `generated_plugins.cmake` are generated plugin-registration files. No plugins are currently registered.

### Windows: `twaq/windows/`

- `CMakeLists.txt` configures the Windows project, build modes, C++17 settings, Flutter engine, installation bundle, and executable name `twaq`.
- `runner/CMakeLists.txt` configures the native Windows runner target.
- `runner/main.cpp` initializes COM, creates the Flutter project, creates a 1280x720 window titled `twaq`, and runs the Win32 message loop.
- `runner/flutter_window.*` creates and manages the Flutter view controller, registers plugins, and forwards native messages.
- `runner/win32_window.*` implement the window class, DPI scaling, theme handling, resizing, and message dispatch.
- `runner/utils.*` attach a debug console, parse command-line arguments, and convert Windows UTF-16 arguments to UTF-8.
- `runner/Runner.rc`, `resource.h`, the manifest, and `resources/app_icon.ico` define Windows resources and application metadata.
- `flutter/CMakeLists.txt`, `generated_plugin_registrant.*`, and `generated_plugins.cmake` are Flutter-tool-managed build and plugin files. No plugins are currently registered.

### Web: `twaq/web/`

- `index.html` is the browser entry document, Flutter bootstrap page, metadata, favicon link, and manifest link.
- `manifest.json` defines the PWA name, theme colors, display mode, orientation, and icons.
- `icons/` contains PWA icon assets; `favicon.png` is the browser favicon.

For web builds, the browser must be able to reach Flask and the Flask service must allow the browser origin through CORS.

## The `twayq` Directory

`twayq/` is not the Flutter application and is not an executable backend in the current repository. It contains only PyCharm/IntelliJ metadata:

- `.idea/misc.xml` selects a Python 3.11 SDK and Black formatter integration.
- `.idea/modules.xml` registers the IDE module.
- `.idea/twayq.iml` declares a Python module and excludes `.venv`.
- `.idea/inspectionProfiles/Project_Default.xml` and `profiles_settings.xml` configure IDE inspections.
- `.idea/.gitignore` excludes local IDE-generated files.

No `.py` files are tracked under `twayq/`, so this directory currently contains no Flask behavior.

## REST API Contract

The contract below is inferred from the Flutter client and should be implemented by the Flask backend.

| Method | Endpoint | Purpose | Data expected by the client |
| --- | --- | --- | --- |
| `GET` | `/status` | Read live monitoring state | `mouse_perc`, `kb_perc`, `overall`, `status_msg`, `is_monitoring` |
| `GET` | `/analytics` | Read charts and averages | `mouse_chart`, `kb_chart`, `stats` |
| `GET` | `/history` | Read monitoring logs | Array items with `time`, `mouse`, `keyboard`, `overall`, `severity` |
| `POST` | `/collect/start` | Start data collection | Successful `2xx` response |
| `POST` | `/collect/stop` | Stop and save collection | Successful `2xx` response |
| `POST` | `/train` | Start behavioral training | Successful `2xx` response |
| `POST` | `/monitor/toggle` | Toggle live monitoring | Successful `2xx` response |

The `/analytics` `stats` object must contain `avg_mouse_speed`, `avg_angle`, `avg_typing_speed`, and `avg_dwell_time`. Percentage fields should be numeric JSON values and `is_monitoring` should be a JSON boolean.

## Installation and Running

### Flutter Frontend

```powershell
cd twaq
flutter pub get
flutter devices
flutter run -d windows
```

Replace `windows` with a device identifier returned by `flutter devices`, such as `chrome` or an Android device ID. Build Windows with:

```powershell
cd twaq
flutter build windows
```

### Python/Flask Backend

The backend files are absent from this repository. After obtaining `backend_api.py` and its official `requirements.txt`:

```powershell
cd path\to\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python backend_api.py
```

The expected address is `http://127.0.0.1:5000`.

### Connecting Both Components

1. Start Flask on port `5000`.
2. Verify `GET http://127.0.0.1:5000/status` returns HTTP 200 and valid JSON.
3. Start Flutter.
4. The dashboard polls `/status` every 4 seconds, analytics polls `/analytics` every 10 seconds, and history polls `/history` every 3 seconds.
5. Collection, training, and monitoring controls send the documented `POST` requests.

PowerShell health check:

```powershell
Invoke-RestMethod http://127.0.0.1:5000/status
```

For an Android emulator, the host machine is commonly available at `10.0.2.2`. For a physical device, use the computer's LAN IP, configure Flask to accept the connection, and allow the port through the firewall if needed. For web, configure CORS in Flask.

## Validation and Limitations

Run the available Flutter checks:

```powershell
cd twaq
flutter analyze
flutter test
```

Known limitations:

- The Flask implementation and Python dependency manifest are not in the current Git repository.
- The Flutter package and native platform identifiers still use `twaq`; this README uses the requested product name **Behavior** without changing code or platform configuration.
- The API base URL is duplicated across Dart files.
- The `http` runtime package is placed under `dev_dependencies`.
- The notification preference is not persisted.
- The analytics user selector does not filter backend requests.
- No license file is included.