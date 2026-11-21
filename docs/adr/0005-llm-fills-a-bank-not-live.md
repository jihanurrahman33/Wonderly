# 0005. On-device LLM fills a local bank, never live in the quiz

Status: Accepted (implemented)

## Context

An on-device model can write fresh questions. Small models are unreliable at
structured output and at facts: they wrap JSON in markdown, truncate, or return
valid JSON with a wrong "correct answer". Live generation also adds latency,
heat and battery drain while a child waits.

## Decision

- The model runs in the **background** (`BankFiller`, `GenerationCubit`) and
  writes candidates into a persisted bank. The quiz reads only the bank; it
  never calls a model.
- A candidate is stored only if it passes every gate in `QuestionGenerator`:
  JSON schema (enforced by the engine where supported), field validation,
  `ValidateQuestion`, `ContentSafety`, duplicate check, and a **second model
  pass that solves the question without the answer key** and must agree.
- Maths, shapes and patterns are written by Dart (`ProceduralGenerator`), not the
  model, because their answers are exactly computable.
- Options are shuffled after validation so the model's position bias is removed.
- Generation pauses while a quiz is open, in the background, when stopped by a
  grown-up, and when the battery is low. Every accepted question is saved
  immediately.
- Each completed round moves to the next window of the bank
  (`CatalogAssembler`), so replays differ.
- A small bundled bank is the safety net until the model has written enough.
- Models: Qwen 2.5 1.5B (balanced) and Gemma 4 E2B (best quality), both Apache 2.0
  and ungated, via `flutter_edge_ai_litertlm`. Gated models (for example
  Gemma 3) are avoided because they would need an access token.

## Consequences

- The app works on any device; the model only improves content.
- Needs the `INTERNET` permission, used solely for the grown-up-approved model
  download (see ADR 0001, amended).
- Quality ceiling: if too many candidates are rejected, offer a larger model
  rather than loosening checks.
- Real speed, memory and acceptance rate must be measured on target phones
  (see docs/RELEASE.md).
