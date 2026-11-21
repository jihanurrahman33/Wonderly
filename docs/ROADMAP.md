# Roadmap

Wonderly 1.0 is feature-complete for its scope: on-device question writing,
A2UI generative cards, six subjects, several learners, sound and music, parent
controls. What follows is polish and growth, not missing core features.

## Needs a real phone (cannot be proven by tests)

- [ ] Measure the models on 2 to 3 target devices: time per question, memory,
      heat, and the share of candidates that pass validation (goal: 90 percent
      or better). Record results in `docs/RELEASE.md`.
- [ ] Decide GPU versus CPU per device class (CPU is used today for stability).
- [ ] Verify `INTERNET` download behaviour on slow and interrupted connections.
- [ ] iOS: add the increased-memory entitlements for large models (see
      `docs/RELEASE.md`) once a team and signing are set up.

## Product

- [ ] Localisation (all strings are English literals today).
- [ ] More subjects and sets by adding `SetBlueprint`s (see `docs/CONTENT.md`).
- [ ] Optional per-learner play limits (limits are device-wide today).
- [ ] Voice input through `flutter_edge_ai_speech` for pre-readers.

## Engineering

- [ ] Migrate generative UI to `a2ui_flutter` when it leaves pre-release
      (ADR 0006); the change is confined to `features/ai/presentation/a2ui`.
- [ ] Move progress to SQLite if per-answer history becomes necessary (ADR 0003).
- [ ] iOS build job in CI (macOS runners).
- [ ] Golden tests for design-critical screens.
