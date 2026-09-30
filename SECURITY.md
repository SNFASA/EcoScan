# Security policy

## Supported version

Security fixes are applied to the latest code on the default branch. This project has not yet published stable release branches.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting feature from the repository's **Security** tab. If that feature is unavailable, contact the repository owner privately using the contact method on their GitHub profile.

Do not open a public issue for leaked credentials, authentication bypasses, personal-data exposure, App Check bypasses, or abuse paths that could consume the project's Firebase or Gemini quota.

Please include:

- the affected version or commit;
- reproduction steps and impact;
- logs or screenshots with credentials and personal data removed; and
- any suggested remediation.

Maintainers should acknowledge a report within seven days. Disclosure timing will be coordinated with the reporter after a fix is available.

## Secret handling

- No Gemini key, service-account JSON, password, or App Check debug token belongs in Git.
- Firebase client configuration and a reCAPTCHA site key are public identifiers, but the associated APIs and domains must still be restricted.
- If a secret is committed, revoke it first; deleting the file in a later commit is not sufficient.
