# EcoScan

EcoScan is ToastTech's guest-first waste-sorting app. Point a camera at a household item and Firebase AI Logic asks Gemini to classify it, suggest a bin, and provide a short recycling tip.

The project began at KitaHack 2026 and is now being prepared as a public Flutter/Firebase project.

## Access model

| Feature | Guest | Registered user |
| --- | :---: | :---: |
| Home | Yes | Yes |
| AI waste scan | Yes | Yes |
| Local session points | Yes | Yes |
| Impact breakdown | Yes | Yes |
| Rankings | No | Yes |

Rankings currently contain preview entries and the signed-in user's local session points. A shared, persistent leaderboard will require a Firestore data model and security rules; the UI calls this out rather than presenting demo values as live data.

## Architecture

```text
Flutter web/mobile
  ├─ Firebase Authentication (email/password, Rankings only)
  ├─ Firebase App Check (abuse protection)
  ├─ Firebase AI Logic → Gemini Developer API (waste scans)
  └─ Riverpod in-memory state (guest points and Impact)

Firebase Hosting serves build/web
```

The app does not contain a Gemini API key. Firebase AI Logic brokers AI calls, and App Check helps reject unauthorized clients. Firebase web configuration in `lib/firebase_options.dart` identifies the Firebase project; it is not a server secret.

## Local development

### Requirements

- Flutter 3.41.1 or a compatible stable release
- A Firebase project with a registered web app
- A browser/device with a camera
- Firebase CLI only if you plan to deploy

### Firebase console setup

1. In **Authentication → Sign-in method**, enable **Email/Password**.
2. In **Firebase AI Logic**, start with the **Gemini Developer API** and enable the required API.
3. In **App Check**, register the web app with a reCAPTCHA Enterprise provider.
4. Add `localhost` for local testing and your Firebase Hosting domains for production.
5. Keep budget alerts and API usage monitoring enabled even when using no-cost quotas.

### Run

```bash
flutter pub get
cp config.example.json config.local.json
flutter run -d chrome --dart-define-from-file=config.local.json
```

Replace the placeholder in `config.local.json` with the public reCAPTCHA Enterprise site key. `config.local.json` is ignored by Git. Do not add a Gemini API key, service-account JSON, passwords, or App Check debug tokens to this repository.

The camera requires HTTPS in production; `localhost` is accepted during development.

## Validate and build

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=config.local.json
```

For detailed Firebase and GitHub deployment setup, see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Project status

- Guest scanning and local Impact state are implemented.
- Rankings are account-gated with Firebase Authentication.
- Shared leaderboard persistence, password reset, account deletion, scan history, and recycling-centre maps are not implemented yet.
- Bin colours are a prototype convention. Disposal guidance varies by local authority and should be verified before a public regional launch.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md).

## License

EcoScan is licensed under the [GNU General Public License v3.0](LICENSE). Derivative distributions must comply with the GPL's source-sharing requirements.
