# Contributing

## Workflow

1. Branch from `main`: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`,
   `chore/<topic>`.
2. Keep changes small and focused. One concern per pull request.
3. Write the test first for domain and bloc logic (red, green, refactor).
4. Open a pull request using the template. CI must be green.
5. Squash-merge into `main`; the PR title becomes the commit message.

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>

<optional body: why, not what>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`.

## Code standards

- `dart format lib test`, `flutter analyze --fatal-infos` clean.
- Strict analysis is on (`strict-casts`, `strict-inference`, `strict-raw-types`).
- **Null safety:** avoid `!`; prefer pattern matching, `?.`, early returns.
- **Immutability:** state and entities are immutable; use `copyWith`.
- **Errors:** return `Result` at boundaries, catch specific exception types,
  never swallow errors silently, never show raw exceptions to children.
- **Layers:** `domain` never imports Flutter or `data`. See
  [ARCHITECTURE](docs/ARCHITECTURE.md).
- Files under about 400 lines (800 hard ceiling), functions under 50 lines,
  nesting under 4 levels.
- Use `package:` imports everywhere.
- No magic numbers: put tunable rules in `AppConstants`.
- Logging goes through `AppLogger`; never log a child's name.

## Kids app rules (non-negotiable)

- No network access, analytics, advertising or crash SDKs that collect
  personal data without an ADR and a policy review.
- No outbound links or purchases reachable by a child.
- Every new control needs a semantic label and a 48 dp touch target, and must
  work at the largest text size on a 320 x 568 screen.

## Tests

- Unit tests for every rule and state transition, including failures.
- Widget tests for flows and layout. `test/helpers/pump_app.dart` boots the
  real app with in-memory storage and bundled fonts.
- Coverage must stay at or above 80 percent (`tool/check_coverage.sh 80`).

## Adding content

Follow [docs/CONTENT.md](docs/CONTENT.md). A second person must verify
facts.

## Decisions

Significant architectural choices get an ADR in `docs/adr`.
