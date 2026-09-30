# Contributing to EcoScan

Thanks for helping ToastTech improve EcoScan.

## Before starting

1. Search existing issues and pull requests.
2. Open an issue for significant behaviour, architecture, privacy, or UI changes.
3. Never post real credentials, private user data, or App Check debug tokens in issues, logs, commits, or screenshots.

## Development workflow

1. Fork the repository and create a focused branch such as `feature/42-password-reset` or `fix/57-camera-error`.
2. Run `flutter pub get`.
3. Make the smallest coherent change and add tests where practical.
4. Run:

   ```bash
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   flutter build web --release
   ```

5. Open a pull request and link its issue with `Closes #42` when applicable.

## Pull request expectations

- Explain the user-visible result and security/privacy impact.
- Keep Home, Scan, local points, and Impact usable by guests.
- Keep Rankings account-gated unless an accepted issue changes the product decision.
- Do not add direct client-side Gemini API keys.
- Update documentation when setup or behaviour changes.
- Avoid unrelated formatting or generated-file changes.

By contributing, you agree that your contribution is licensed under GPL-3.0 and to follow the project's Code of Conduct.
