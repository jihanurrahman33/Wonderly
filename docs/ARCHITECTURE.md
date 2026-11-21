# Architecture

Wonderly follows **Clean Architecture** with a **feature-first** layout and
**BLoC** for presentation state.

## Layers

```
presentation  ->  domain  <-  data
(widgets,         (entities,    (repository impls,
 bloc/cubit)       interfaces,   parsers, storage)
                   use cases,
                   services)
```

| Layer | May import | Must not import |
|---|---|---|
| `domain` | Dart core, `equatable`, other domains | Flutter, `data`, `presentation`, plugins |
| `data` | `domain`, `core`, storage and asset APIs | `presentation` |
| `presentation` | `domain`, `core`, Flutter, `flutter_bloc` | `data` (except via the DI root) |

Cross-feature imports go through `domain` types only (for example `quiz` uses
`learning` and `progress` entities). `core/di/injection.dart` is the single
composition root; nothing else resolves dependencies from the service locator
except route builders and a few page-level `State` fields.

## Features

| Feature | Responsibility |
|---|---|
| `onboarding` | Splash and three-step welcome tour |
| `profile` | Learners (several per phone), validation, setup form, switcher |
| `learning` | Curriculum blueprints, procedural generators, catalog assembly, validation |
| `ai` | On-device model: `LlmClient`, model manager, question generator, bank filler, A2UI agent, validator and catalog |
| `quiz` | The quiz session: `QuizBloc`, question views, results |
| `progress` | Stars, streaks, badges, weekly stats, rewards screens |
| `parent` | Parent gate, grown-ups dashboard, in-memory parent session |
| `settings` | Preferences, daily limit and bedtime rules (`PlayGuard`) |
| `home` | Home dashboard |

## State management

- **App-wide cubits** (singletons, created in DI, provided at the root):
  `ProfileCubit`, `ProgressCubit`, `SettingsCubit`, `CatalogCubit`.
- **Per-screen state**: `QuizBloc` (a Bloc, because it is event driven),
  `ProfileSetupCubit`, `ParentGateCubit`. They are created by `BlocProvider`
  when the route opens and closed when it closes.
- State classes are immutable (`Equatable`, `copyWith`). Nothing mutates a
  collection in place.
- `QuizBloc` uses `droppable()` for Next (a double tap cannot count an answer
  twice) and `sequential()` for ticks (no lost seconds).

## Data flow: answering a question

```
Option tap -> QuizBloc(QuizOptionSelected)
Next tap   -> QuizBloc(QuizNextPressed)
              -> RecordAnswer use case
                 -> ProgressRepository.update(transform)
                    -> ProgressReducer.applyAnswer (pure)
                       stars, cursor, completion, streak, badges
                    -> JsonValueRepository: persist, emit on watch()
              <- AnswerOutcome (stars gained, new badges)
QuizState(revealed, lastCorrect, lastStars) -> FeedbackPanel
ProgressCubit (listening to watch()) -> Home, Rewards, Progress refresh
```

All business rules live in pure functions (`ProgressReducer`, `BadgeRules`,
`StreakCalculator`, `PlayGuard`, `ValidateQuestion`, `ValidateProfile`) so they
are tested without Flutter.

## Persistence

`JsonValueRepository<T>` keeps one JSON document per concern
(`profile`, `progress`, `settings`) in a `KeyValueStore` (shared preferences in
production, in-memory in tests). It provides:

- an in-memory cache and a broadcast `watch()` stream,
- **serialised updates** through a future queue, so concurrent callers cannot
  overwrite each other,
- **self-healing reads**: corrupt or wrongly shaped JSON falls back to defaults
  and is logged instead of crashing,
- write failures returned as `StorageFailure` while the previous value stays
  authoritative.

Keys are versioned. Progress is stored per learner (`wonderly.progress.v2.<id>`;
the pre-roster learner keeps `wonderly.progress.v1`), and `rebind(key)` switches
learners through the same serialised queue (ADR 0007).

## On-device AI

```
Curriculum (SetBlueprint)
  |-- procedural: ProceduralGenerator (maths, shapes, patterns)  --\
  |-- llm:        BankFiller -> QuestionGenerator -> GeneratedBank --+-> CatalogAssembler -> Catalog -> QuizBloc
  `-- safety net: assets/data/questions.json (until a full round exists) --/
```

- `LlmClient` is the seam to the model (`EdgeAiLlmClient` in production, a
  scripted fake in tests). Calls are serialised, failures are `Result`s, the
  model is released after each batch, and a failed model is reloaded next time.
- `ModelManager` owns the model file life cycle (`ModelStatus`): unsupported,
  not installed, downloading (with cancel), installed, failed. Hardware checks
  (Android 11+, arm64, memory per profile; iOS 15+) live in
  `DeviceCapabilityChecker`.
- `QuestionGenerator` accepts a question only after schema, field, safety,
  structure, duplicate and **second-pass self-check** validation (ADR 0005).
- `GenerationCubit` runs `BankFiller` politely: paused for an open quiz, the
  background, a user stop, or low battery; every accepted question is saved at
  once. The `CatalogCubit` listens to bank and progress changes (debounced) and
  republishes the catalog without a loading flash.
- `CatalogAssembler` builds the playable catalog for the active learner:
  windows of the bank advance with each completed round; procedural sets follow
  grade and day.

### Generative UI (A2UI)

`BuddyAgent` asks the model for a card, `A2uiValidator` reduces the reply to
plain values (or rejects it), and the app emits the A2UI messages through
`A2uiTransportAdapter` into genui's `SurfaceController`, drawn by `Surface` with
`WonderlyCatalog` (ADR 0006). A deterministic fallback keeps the card present
and correct when the model is unavailable.

## Content pipeline

See [CONTENT.md](CONTENT.md). Generated and bundled questions pass the same
`ValidateQuestion` rules; `GeneratedBank` re-validates everything it loads.

## Error handling

- Boundaries return `Result<T>` with a sealed `Failure`
  (`StorageFailure`, `DataFailure`, `ValidationFailure`, `PlatformFailure`).
- Catch clauses name their exception types. The only `on Object` is the
  repository update queue, which logs and converts to a failure so one bug
  cannot wedge every later save.
- `bootstrap()` installs `FlutterError.onError`, `PlatformDispatcher.onError`
  and a zone guard, logs through `AppLogger`, and swaps the red error screen
  for a friendly message in release builds.
- UI never shows raw exceptions. Load failures show a retry (`MessageView`),
  save failures show a snackbar addressed to a grown-up.
- Logs never contain the child's name.

## Navigation

`go_router` with `StatefulShellRoute.indexedStack` for the four tabs (Home,
Learn, Rewards, Me). A redirect:

1. keeps the app on the splash until the profile has loaded,
2. sends users without a profile back to splash/onboarding,
3. sends `/grown-ups` to `/parent-gate` unless a parent session is active
   (`ParentAccess`, in memory, five minutes, never persisted).

## Safety rules (domain)

- **Play limit:** `PlayGuard.check` combines today's seconds, the daily limit
  and bedtime mode. `QuizBloc` checks it on start and every five seconds, then
  moves to `QuizStatus.blocked` and shows the break screen. Time only counts
  while the app is in the foreground.
- **Parent gate:** two-digit multiplication from 6x6 to 9x9; three wrong
  answers lock input for 30 seconds.
- **Content:** every question passes `ValidateQuestion` (distinct options,
  valid answer index, prompt of 15 words or fewer).

## Accessibility

Semantic labels on every control, 48 dp minimum touch targets, no information
conveyed by colour alone (marks use icons), text-size setting honoured through
`MediaQuery.withClampedTextScaling`, drag-and-match has a tap alternative, and
a widget test checks layout on a 320x568 phone at the largest text size.

## Testing

| Kind | Where | Examples |
|---|---|---|
| Unit | `test/unit` | reducers, badge and streak rules, play guard, validators, parser, repositories, cubits, `QuizBloc` |
| Widget / flow | `test/widget` | first-run flow, tabs, all four question types, break screen, parent gate, rewards, small-screen layout |

Fonts are loaded in widget tests so overflow checks use real glyph widths.
CI enforces at least 80 percent line coverage.
