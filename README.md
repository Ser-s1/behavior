# Behavior | Behavioral Biometrics Dashboard

Behavior is a Flutter dashboard for monitoring and analyzing mouse and keyboard behavioral biometrics. It is designed to work with a Python/Flask service that collects input events, analyzes behavioral patterns, and exposes trust indicators through a REST API.

> **Repository status:** The current workspace contains the Flutter client and its backend call sites, but it does not currently include the Flask source file (`backend_api.py`) or a Python dependency manifest (`requirements.txt`). The backend must be supplied separately before the complete system can run end to end.

## English Documentation

### Project Overview

The application presents behavioral biometric information in a security dashboard. It polls the backend for live status, historical analytics, and monitoring history, while also providing controls for collection, training, and live monitoring.

The system is split into two logical components:

- **Flutter frontend:** the user interface, charts, controls, polling, and error states. It is located in `twaq/`.
- **Python/Flask backend:** input-event collection, feature extraction, behavioral analysis, model training, monitoring, and REST endpoints. The backend implementation is not included in the current workspace.

### Main Features

- Live mouse behavior match percentage.
- Live keyboard-style match percentage.
- Overall system trust score.
- Start and stop data collection.
- Save a collection session through the stop operation.
- Trigger behavioral or AI training.
- Toggle live monitoring.
- Historical mouse-speed and typing-intensity charts.
- Statistics for average mouse speed, movement angle, typing speed, and key dwell time.
- Monitoring history with mouse score, keyboard score, overall score, severity, and timestamp.
- Security settings with periodic warnings when the trust score falls below 50%.

### Project Structure

```text
.
├── README.md
├── twaq/
│   ├── lib/
│   │   ├── main.dart              # Main dashboard and backend commands
│   │   ├── analytics_page.dart    # Charts and biometric statistics
│   │   ├── history_page.dart      # Monitoring history
│   │   ├── settings_page.dart     # Monitoring and notification settings
│   │   └── custom_widgets.dart    # Shared cards, buttons, and charts
│   ├── pubspec.yaml               # Flutter/Dart dependencies
│   ├── pubspec.lock
│   ├── analysis_options.yaml
│   └── android/, ios/, linux/, macos/, web/, windows/
└── twayq/                         # IDE metadata in the current workspace
```

### Requirements

#### Frontend

- Flutter SDK compatible with the Dart constraint `^3.10.7`.
- A configured Flutter device or target, such as Windows, Android, or Chrome.
- Android Studio and an Android SDK when targeting Android.
- Xcode when targeting iOS or macOS.
- Network access between the Flutter process and the Flask service.

#### Backend

- Python 3.10 or newer is recommended.
- `pip` and a Python virtual environment.
- The backend's official `requirements.txt`.
- Operating-system permissions required to capture mouse and keyboard events.
- A free local TCP port `5000`, unless both components are configured to use another port.

Check the installed toolchains:

```powershell
flutter --version
flutter doctor
python --version
```

### Frontend Installation and Run

From the repository root, install the Dart packages and select a target:

```powershell
cd twaq
flutter pub get
flutter devices
flutter run -d windows
```

Replace `windows` with a device identifier shown by `flutter devices`, for example `chrome` or an Android device ID.

The Flutter manifest currently declares:

- `fl_chart` for line charts and visual analytics.
- `http` for HTTP communication with Flask.
- `flutter_lints` for static analysis.
- `flutter_test` for Flutter tests.

To build a Windows release package:

```powershell
cd twaq
flutter build windows
```

### Backend Installation and Run

The backend files are not present in this repository snapshot. Once `backend_api.py` and its official `requirements.txt` are available, create an isolated environment and start Flask as follows:

```powershell
cd path\to\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python backend_api.py
```

The service is expected to listen at:

```text
http://127.0.0.1:5000
```

Do not infer the backend package list from the Flutter project. Python dependencies must come from the backend's own `requirements.txt`, because the current workspace does not expose the implementation details needed to verify input-capture or machine-learning libraries.

### Frontend-Backend Integration

The Flutter client currently uses the fixed base URL `http://127.0.0.1:5000`. The client polls read endpoints periodically and sends control operations as HTTP `POST` requests.

| Method | Endpoint | Purpose | Response data used by Flutter |
| --- | --- | --- | --- |
| `GET` | `/status` | Read live monitoring and biometric status | `mouse_perc`, `kb_perc`, `overall`, `status_msg`, `is_monitoring` |
| `GET` | `/analytics` | Read chart data and summary statistics | `mouse_chart`, `kb_chart`, `stats` |
| `GET` | `/history` | Read monitoring events | Array containing `overall`, `mouse`, `keyboard`, `severity`, and `time` |
| `POST` | `/collect/start` | Start collecting input data | Any successful `2xx` response |
| `POST` | `/collect/stop` | Stop collection and save the session | Any successful `2xx` response |
| `POST` | `/train` | Start behavioral or AI training | Any successful `2xx` response |
| `POST` | `/monitor/toggle` | Enable or disable live monitoring | Any successful `2xx` response |

The `/analytics` response must provide a `stats` object with:

- `avg_mouse_speed`
- `avg_angle`
- `avg_typing_speed`
- `avg_dwell_time`

### Recommended Startup Sequence

1. Start the Flask backend on port `5000`.
2. Check that `GET http://127.0.0.1:5000/status` returns HTTP 200 and valid JSON.
3. Start the Flutter application.
4. The dashboard refreshes `/status` every 4 seconds.
5. The analytics page refreshes `/analytics` every 10 seconds.
6. The history page refreshes `/history` every 3 seconds.
7. Collection, training, and monitoring buttons send `POST` commands and refresh the dashboard state.

Example health check from PowerShell:

```powershell
Invoke-RestMethod http://127.0.0.1:5000/status
```

### Android Emulator and Physical Devices

`127.0.0.1` refers to the device running Flutter. It works when the client and backend share the same desktop environment. For an Android emulator, the host machine is commonly reachable through `10.0.2.2`; for a physical Android device, use the computer's LAN IP address.

When using Android or another separate device:

1. Configure Flask to bind to an address reachable from the device, if appropriate for the development network.
2. Allow the selected port through the local firewall when necessary.
3. Replace the hard-coded Flutter URL with the correct host address.
4. Keep the API base URL in one configuration value rather than duplicating it across pages.

### Testing and Troubleshooting

Run the available Flutter checks from `twaq/`:

```powershell
cd twaq
flutter analyze
flutter test
```

Common problems:

- **Connection error:** verify that Flask is running on port `5000` and that the selected Flutter target can reach it.
- **Empty charts or history:** start collection or monitoring and verify that the backend returns the documented JSON fields.
- **Permission error:** grant the backend permission to observe mouse and keyboard events.
- **Android connection failure:** use `10.0.2.2` for the standard Android emulator or the computer's LAN IP for a physical device.
- **Dependency resolution failure:** run `flutter clean` followed by `flutter pub get` inside `twaq/`.
- **Unexpected status values:** confirm that percentages are numeric JSON values and that `is_monitoring` is a JSON boolean.

### Current Limitations

- The Flask implementation and Python dependency manifest are absent from the current workspace.
- The Flutter client duplicates the API base URL in several Dart files.
- The `http` package is currently listed under `dev_dependencies` even though application code imports it; it should normally be a regular runtime dependency.
- The repository does not currently include a license file.

## التوثيق العربي المختصر

### نبذة

مشروع **Twaq** عبارة عن لوحة تحكم Flutter لتحليل البصمة السلوكية للماوس ولوحة المفاتيح، مع خلفية Python/Flask تجمع الأحداث وتحللها وتعيد مؤشرات الثقة.

### التشغيل

تشغيل الواجهة:

```powershell
cd twaq
flutter pub get
flutter run -d windows
```

تشغيل الخلفية بعد توفير ملفاتها:

```powershell
cd path\to\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python backend_api.py
```

يجب أن تعمل الخلفية على `http://127.0.0.1:5000`.

### الربط

تستخدم الواجهة المسارات التالية:

- `GET /status` للحالة الحالية.
- `GET /analytics` للتحليلات والمخططات.
- `GET /history` للسجل.
- `POST /collect/start` و`POST /collect/stop` لجمع البيانات.
- `POST /train` للتدريب.
- `POST /monitor/toggle` لتشغيل أو إيقاف المراقبة.

> ملفات Flask و`requirements.txt` غير موجودة حاليًا في المستودع، لذلك يلزم إضافتها قبل تشغيل النظام كاملًا. في Android Emulator استخدم غالبًا `10.0.2.2` بدل `127.0.0.1`.
