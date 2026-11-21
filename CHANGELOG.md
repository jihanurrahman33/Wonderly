# Changelog

All notable changes are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-11-21

First complete build of the app from the Wonderly design reference.

### Added

- 23 screens: splash, welcome tour, profile setup, home, subjects, subject
  quiz sets, four quiz types, results with answer review, rewards, badges,
  progress, profile, parent gate, grown-ups dashboard, settings.
- Offline seed question bank (50 questions) with a validation gate.
- Stars, streaks, six badges, per-set resume and weekly progress.
- Parent gate with lockout, daily play limit that ends a session, bedtime mode.
- Read aloud (on-device text to speech), haptic feedback, text size setting.
- Clean Architecture, BLoC, `go_router`, `get_it`, `Result`-based error
  handling and global error logging.
- 140 automated tests with more than 90 percent line coverage; CI with format,
  analyze, test, coverage threshold and an Android build.
- Project documentation, ADRs, release guide and GitHub templates.

### Not included

- On-device LLM question generator (see `docs/ROADMAP.md`).
- Sound effects and music audio, email reports, multiple learners.
