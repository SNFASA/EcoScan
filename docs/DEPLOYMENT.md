# Firebase deployment guide

This project can remain on Firebase while staying within no-cost quotas for a student prototype. Free quotas are limits, not a guarantee against abuse, so App Check, monitoring, and conservative AI usage remain required.

## 1. Rotate credentials before publishing

The old `.env` file was tracked in Git history. Deleting it from the latest commit does not revoke or erase its values.

1. Revoke and replace every Gemini, Google Places, mail, or other credential that ever appeared in `.env`.
2. Review Google Cloud credentials and restrict browser keys by API and allowed domain.
3. Remove the historical file with `git filter-repo` only after the team has backed up the repository and agreed to rewrite shared history.
4. Force-push the rewritten branches, then have every contributor re-clone.
5. Enable GitHub secret scanning and push protection where available.

Do not perform the history rewrite casually: it changes commit IDs for everyone.

## 2. Configure Firebase services

Using Firebase project `ecoscan-aaa86`:

1. Enable Email/Password in Firebase Authentication. Authentication is used only by Rankings.
2. Open Firebase AI Logic, choose the Gemini Developer API, and complete its setup flow.
3. Register every supported app in App Check. For web, create a reCAPTCHA Enterprise site key and allow the Hosting domains plus `localhost` for development.
4. Start App Check in monitoring mode. Review metrics before enforcing it for Firebase AI Logic and Authentication.
5. Add usage alerts in Google Cloud and monitor AI request volume.

The reCAPTCHA site key and generated Firebase client configuration are public client identifiers. Service-account private keys, legacy Gemini keys, and App Check debug tokens are secrets.

## 3. Build locally

Create the ignored `config.local.json` from `config.example.json`, then run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=config.local.json
```

## 4. Test Firebase Hosting

```bash
firebase login
firebase use ecoscan-aaa86
firebase emulators:start --only hosting
```

Verify these paths before release:

- Home, Scan, and Impact open without signing in.
- Rankings shows a sign-in/register form to guests.
- A registered user can view Rankings and sign out.
- Camera permission denial produces a recoverable error.
- A valid scan returns structured results and updates local points.
- Refreshing the page clears guest session points, as documented.

## 5. Deploy manually

```bash
flutter build web --release --dart-define-from-file=config.local.json
firebase deploy --only hosting
```

## 6. Enable GitHub deployment

The workflow in `.github/workflows/ci.yml` runs formatting, analysis, tests, and a release build on pull requests. Pushes to `main` also deploy to Firebase Hosting.

Add these GitHub Actions repository secrets:

- `RECAPTCHA_ENTERPRISE_SITE_KEY`: the public web site key used at build time.
- `FIREBASE_SERVICE_ACCOUNT_ECOSCAN_AAA86`: the complete JSON for a narrowly scoped Firebase Hosting deployment service account. The Firebase CLI's Hosting GitHub integration can create this secret and workflow permissions for you.

Protect `main`, require the CI job, and use pull requests. Do not allow workflow runs from untrusted forks to access deployment secrets.

## 7. Production checks

1. Confirm authorized Firebase Auth domains include the deployed Hosting domain.
2. Confirm the reCAPTCHA Enterprise key permits the deployed domain.
3. Test in a private browser session as a guest and as a newly registered user.
4. Review App Check and Firebase AI Logic usage after launch.
5. Add a privacy notice before storing shared leaderboard profiles or scan history.

## Future persistent leaderboard

Do not let clients submit arbitrary totals. A proper implementation should use Firestore rules that require authentication and a trusted calculation path for score changes. Cloud Functions generally require the Blaze billing plan, so decide whether persistent global rankings justify billing before implementing that design.
