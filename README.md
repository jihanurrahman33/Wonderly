# Wonderly

A playful, **offline-first** learning app for children in grades 1 to 5. One
question per screen, stars and badges for motivation, and a protected
grown-ups zone with a daily play limit.

[![CI](https://github.com/jihanurrahman33/Wonderly/actions/workflows/ci.yml/badge.svg)](https://github.com/jihanurrahman33/Wonderly/actions/workflows/ci.yml)

## Highlights

- **23 screens** built from the design reference in
  [`docs/design`](docs/design/README.md) (splash, welcome tour, profile setup,
  home, subjects, four quiz types, results, rewards, badges, progress,
  profile, parent gate, grown-ups dashboard, settings).
- **Works with no network and no AI.** A hand-checked seed question bank ships
  in the app. The app declares no `INTERNET` permission, uses no analytics and
  contains no external links.
- **Four question types** behind one quiz engine: picture grid, text list,
  pattern completion and drag-and-match (with a tap alternative for
  accessibility).
- **Safety by design:** parent gate (maths question with lockout), daily play
  limit that really ends a session, optional bedtime mode, validated content.
- **Production practices:** clean architecture, BLoC, dependency injection,
  sealed types, `Result`-based error handling, null safety with strict
  analysis, 140 automated tests.

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.47 / Dart 3.13 (sound null safety) |
| State management | `flutter_bloc` (Bloc and Cubit), `bloc_concurrency` |
| Navigation | `go_router` with a stateful shell for the tab bar |
| Dependency injection | `get_it` (composition root only) |
| Persistence | `shared_preferences` behind repository interfaces |
| Text to speech | `flutter_tts` (offline, on-device voices) |
| Artwork | bundled SVG via `flutter_svg`; Fredoka and Nunito fonts bundled |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |

## Getting started

```bash
flutter pub get
flutter analyze
flutter test --coverage
tool/check_coverage.sh 80
```

Run it on a device or simulator with `flutter run` (supported: Android and iOS,
portrait only).

### Quality gates

CI runs on every pull request and must pass before merging:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --coverage && tool/check_coverage.sh 80
```

## Project structure

```
lib/
  main.dart, app.dart, bootstrap.dart   entry point, root widget, global error handling
  core/                                 shared, feature-agnostic code
    constants/  di/  error/  router/  services/  storage/  theme/  utils/  widgets/
  features/<feature>/
    domain/        pure Dart: entities, repository interfaces, use cases, services
    data/          repository implementations, parsers
    presentation/  blocs/cubits, pages, widgets
assets/            svg/ (illustrations), fonts/, data/questions.json (seed bank)
docs/              architecture, ADRs, design mapping, release guide, roadmap
test/              unit/, widget/, helpers/
```

Features: `onboarding`, `profile`, `home`, `learning`, `quiz`, `progress`,
`parent`, `settings`. Dependencies point inward: presentation depends on
domain, data depends on domain, and domain depends on nothing.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full picture and
[`docs/adr`](docs/adr/README.md) for the decisions behind it.

## Documentation

| Document | What it covers |
|---|---|
| [ARCHITECTURE](docs/ARCHITECTURE.md) | Layers, data flow, state, error handling, testing |
| [DESIGN_MAPPING](docs/DESIGN_MAPPING.md) | Every design screen mapped to code, plus deliberate deviations |
| [CONTENT](docs/CONTENT.md) | How to add or change questions safely |
| [RELEASE](docs/RELEASE.md) | Signing, store policies for kids apps, release checklist |
| [ROADMAP](docs/ROADMAP.md) | On-device question generator plan and what is not built yet |
| [ADRs](docs/adr/README.md) | Architecture decision records |
| [CONTRIBUTING](CONTRIBUTING.md) | Branching, commits, reviews |
| [SECURITY](SECURITY.md) | Reporting vulnerabilities |
| [CHANGELOG](CHANGELOG.md) | Release notes |

## Privacy

Everything stays on the device: the learner's name, buddy, grade, progress and
settings. There is no account, no analytics, no advertising and no network
code. Removing the app erases all data.

## Known limitations

- The on-device LLM question generator described in the roadmap is **not
  implemented**; the app ships with the validated seed bank.
- Sound effects are haptic only and the Music toggle is stored but plays
  nothing, because no audio assets are bundled yet.
- "Weekly report" is a stored preference. Nothing is emailed because the app
  has no backend.
- Numbers and Words are shown as "Coming soon", as in the design.
- Single learner per install ("Switch learner" from the design is omitted).
- Release builds are signed with the debug key until a keystore is configured
  (see [RELEASE](docs/RELEASE.md)).
