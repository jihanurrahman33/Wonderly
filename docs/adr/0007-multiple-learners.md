# 0007. Several learners per device with per-learner progress

Status: Accepted

## Context

Siblings share phones. A single global profile would mix their stars, streaks and
quizzes.

## Decision

- `LearnerRoster` (a list of `LearnerProfile` plus the active id) is stored as one
  document. Each learner has a stable uuid.
- Progress is stored per learner (`wonderly.progress.v2.<id>`). `JsonValueRepository`
  gained `rebind(key)`, so switching learners reloads another document through the
  same serialised queue and `watch()` stream.
- Data from versions with one profile is migrated on first read into a learner with
  id `legacy`, which keeps the original progress key, so nothing is lost.
- Switching learners is one tap on Profile. Removing a learner (which erases their
  progress) lives in the grown-ups zone behind the parent gate.
- The question bank is shared; the catalog is rebuilt for the active learner's grade
  and per-set rounds.

## Consequences

- Fresh content per child with no duplication of the model's work.
- Parent-set limits and settings are device-wide, not per learner.
