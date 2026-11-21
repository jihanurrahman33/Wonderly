# 0002. BLoC with Clean Architecture and feature-first layout

Status: Accepted

## Context

The product plan suggested Riverpod; the project requirement is BLoC, clean
code, SOLID and testability. The app has genuinely event-driven flows (the quiz
session) and simpler state holders (settings, profile).

## Decision

- Feature-first folders, each split into `domain`, `data`, `presentation`.
  Dependencies point inward; `domain` is pure Dart.
- `Bloc` where events matter (`QuizBloc`); `Cubit` for simple state
  (`ProfileCubit`, `SettingsCubit`, `ProgressCubit`, `CatalogCubit`,
  `ProfileSetupCubit`, `ParentGateCubit`).
- Business rules are pure functions or small classes in `domain`
  (`ProgressReducer`, `BadgeRules`, `PlayGuard`, ...), tested without Flutter.
- Use cases exist where an operation orchestrates repositories
  (`RecordAnswer`, `RecordPlayTime`, `ValidateProfile`). Trivial pass-through
  reads call the repository from a cubit rather than adding empty wrappers.
- `get_it` is the composition root. Time, storage, speech and content are
  injected behind interfaces (`Clock`, `KeyValueStore`, `SpeechService`,
  `CatalogRepository`) so tests use fakes.
- Sealed classes with exhaustive `switch` model closed sets: `Question`,
  `Failure`, `Result`, `PlayAllowance`, `CatalogState`.

## Consequences

- Rules are fast to test (140 tests run in seconds).
- Slightly more files than a single-layer app; accepted for clarity.
- The service locator is visible in a few `State` fields and route builders.
  It is not used inside domain or data code.
