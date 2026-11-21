# 0004. Parent gate and play limits enforced in the domain

Status: Accepted

## Context

Parents need control (daily limit, bedtime, progress) and children must not be
able to change it. The app has no accounts, so protection is local.

## Decision

- **Parent gate:** a random two-digit multiplication (factors 6 to 9). Three
  wrong answers lock input for 30 seconds. A successful answer grants an
  in-memory `ParentAccess` session for five minutes; it is never persisted, so
  restarting the app asks again. The router redirects `/grown-ups` to the gate
  without a session.
- **Play limit:** `PlayGuard` (pure) decides allowed or blocked from the clock,
  today's seconds, the limit and bedtime mode. `QuizBloc` consults it when a
  quiz starts and every five seconds of play, persisting time as it goes, and
  moves to a blocked state that shows the break screen. Time only counts while
  the app is in the foreground.
- Bedtime mode changes in Settings also require the gate.

## Consequences

- The limit cannot be bypassed by leaving and re-entering a quiz, because used
  time is persisted.
- A determined child can still change the device clock. Mitigation (a monotonic
  clock or server time) is out of scope for an offline app and noted as a known
  limit.
- The gate is a deterrent suited to young children, not a security boundary.
