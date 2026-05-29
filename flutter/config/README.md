# App configuration (`--dart-define-from-file`)

Compile-time configuration for the app's API base URL. Each file injects its
top-level keys as `--dart-define` values; the app reads `BASE_URL` via
`String.fromEnvironment('BASE_URL')` into `AppConfig.baseUrl`.

These files live **outside** `assets/` so they are never bundled into the web
build and never exposed as fetchable public assets.

Pass exactly one file at build/run time. Omitting it makes the app refuse to
start with a `StateError` naming this directory.

| File | `BASE_URL` | Purpose | Command |
|---|---|---|---|
| `local-web.json` | `http://127.0.0.1:8000/api/v1` | Local web (Chrome) against local FastAPI | `flutter run -d chrome --dart-define-from-file=flutter/config/local-web.json` |
| `local-android-emulator.json` | `http://10.0.2.2:8000/api/v1` | Android emulator (host loopback is `10.0.2.2`) | `flutter run --dart-define-from-file=flutter/config/local-android-emulator.json` |
| `local-ios-simulator.json` | `http://127.0.0.1:8000/api/v1` | iOS simulator (shares host loopback) | `flutter run --dart-define-from-file=flutter/config/local-ios-simulator.json` |
| `local-desktop.json` | `http://127.0.0.1:8000/api/v1` | macOS/Windows/Linux desktop | `flutter run --dart-define-from-file=flutter/config/local-desktop.json` |
| `prod-web.json` | `/api/v1` | Production web; same-origin ingress path. Baked into the Docker image. | `flutter build web --release --dart-define-from-file=flutter/config/prod-web.json` |

`prod-mobile.json` is intentionally absent: there is no production mobile domain
yet. Its absence is the documented signal that prod-mobile is unsolved.
