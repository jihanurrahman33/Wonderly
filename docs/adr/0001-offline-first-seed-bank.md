# 0001. Offline-first with a validated seed question bank

Status: Accepted

## Context

Wonderly is for children aged about 6 to 11. Store policies for kids apps
restrict data collection, tracking and outbound links, and a backend adds
cost, privacy risk and failure modes. Quiz correctness matters more than
volume: a wrong "right answer" teaches a child something false.

## Decision

- The app is fully offline. No backend, no analytics, no ads, no
  `INTERNET` permission.
- Content ships as a hand-checked JSON seed bank (`assets/data/questions.json`).
- Every question passes `ValidateQuestion` before it can be shown. Invalid
  questions are skipped and logged, and a test fails the build if an authored
  question is rejected.
- Content is read through the `CatalogRepository` interface.

## Consequences

- Easy store review and a strong privacy story ("nothing leaves the device").
- No crash or usage telemetry; quality relies on tests and manual QA.
- Content updates ship with app releases.
- A generated or downloaded source can be added later behind the same
  interface without touching the quiz engine (see ADR 0005).
