# 0006. Generative UI through A2UI, with a validated, tiny catalog

Status: Accepted

## Context

The product is an on-device-AI showcase, so the model should shape parts of the
interface, not only content. The A2UI protocol (rendered in Flutter by `genui`)
lets an agent describe UI as messages. Letting a small model emit arbitrary UI
for children would be unsafe and unreliable.

## Decision

- **Smart Buddy** is an on-device agent (`BuddyAgent`). It receives a compact
  JSON brief (name, grade, stars, streak, suggested quiz) and replies with A2UI.
- The reply is parsed by `A2uiValidator`: exactly one `BuddyCard`, optionally one
  `ActionButton` that starts a quiz from an allow-list, every string
  length-limited and passed through `ContentSafety`. The validator returns plain
  values and the **app builds the A2UI messages itself**, so unchecked model
  output never reaches the renderer.
- Messages flow through `A2uiTransportAdapter` into `SurfaceController` and are
  drawn by genui's `Surface`, so the integration is real A2UI, not a lookalike.
- The catalog (`WonderlyCatalog`) has cards, text, layout, a stat tile and an
  action button. No image, video, audio, link or input components exist.
- If the model is unavailable, slow (90 s limit), busy generating questions, or
  invalid, deterministic built-in text is used, so the card always appears.
- Two surfaces ship: a child's Home tip and the grown-ups' weekly note (with
  app-built stat tiles beside the model's words).

## Consequences

- Safe by construction; the model controls wording and the next-quiz choice.
- `genui` is marked discontinued on pub.dev in favour of `a2ui_flutter`, which is
  still a pre-release (`0.0.1-wip`). We stay on `genui` 0.10.x and keep every use
  inside `features/ai/presentation/a2ui` so migrating later touches one folder.
- Action handling is a direct callback (not a chat round-trip), so taps are
  instant and never re-prompt the model.
