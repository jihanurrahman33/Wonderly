# Security policy

Wonderly is an offline app for children. It stores a first name, a chosen
animal buddy, a grade and learning progress on the device only, and it uses the network only
to download its on-device model after a grown-up approves it.

## Reporting a vulnerability

Please do **not** open a public issue for security problems. Use GitHub's
private vulnerability reporting on this repository (Security tab, "Report a
vulnerability"). Include steps to reproduce and the affected version. You can
expect an acknowledgement within a few days.

## Scope examples

- Ways to bypass the parent gate or the daily limit without changing the
  device clock.
- Anything that causes the app to transmit data or open external content.
- Crashes or data loss triggered by corrupt local data.

## Secrets

No secrets belong in this repository. Signing keys and `android/key.properties`
are git-ignored; see [docs/RELEASE.md](docs/RELEASE.md).
