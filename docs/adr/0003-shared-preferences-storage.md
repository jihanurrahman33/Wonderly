# 0003. JSON documents in shared preferences for persistence

Status: Accepted

## Context

The plan proposed Drift (SQLite). The data to persist is small and
document-shaped: one profile, one settings object and one progress aggregate
(stars, per-set cursor, daily totals, badges). There are no ad-hoc queries and
no per-attempt history in the current screens.

## Decision

Store one versioned JSON document per concern in `shared_preferences` through
`JsonValueRepository<T>`, with an in-memory cache, a `watch()` stream,
serialised updates and self-healing reads. Hide it behind repository
interfaces so the storage engine is replaceable.

## Consequences

- No code generation, no migrations tooling and no native database.
- Atomic whole-document writes; the update queue prevents lost updates.
- Not suited to large histories. If per-answer analytics or multiple learners
  with long history are needed, add Drift behind the same repository
  interfaces and migrate from the `v1` keys.
- Data is not encrypted. It holds a first name and learning progress only;
  nothing sensitive (no credentials, tokens or contact data) is stored.
