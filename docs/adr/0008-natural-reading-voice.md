# 0008. A downloaded neural voice for read aloud, with the system voice as fallback

Status: Accepted (implemented)

## Context

The platform text to speech voices are often the oldest, most robotic ones on a
device, and a high pitch made them sound like a toy. Better system voices
(enhanced, premium) exist, but only if the user has downloaded them.

## Decision

- Read aloud uses **Kokoro** (Apache 2.0) run on the device by `sherpa_onnx`,
  downloaded once (about 150 MB) after a grown-up taps "Download natural voice"
  on the Smart Buddy page. It then works fully offline.
- `NaturalVoice` wraps the system voice: until the neural voice is installed, or
  if anything fails, the system voice reads instead, so a child always hears
  something.
- The system voice itself is improved too: `VoicePicker` chooses the best
  installed English voice (premium and enhanced first, never novelty voices,
  never ones that need the internet), at a natural pitch and pace.
- `sherpa_onnx` is **pinned to 1.13.8**. Version 2.0 removed the built in
  text to phoneme step, so Piper models produced no audio; Kokoro was verified
  against 1.13.8.
- Piper (65 MB) was also tried. Kokoro sounded clearly more human, so it is
  the only voice kept.

## Consequences

- A second grown-up approved download, so privacy copy and `docs/RELEASE.md`
  say "the model file and the reading voice".
- About 210 MB of extra storage on devices that install it, removable from the
  same card.
- Generation runs on the main isolate; sentences are short, but profile on
  low end phones and move it to a background isolate if it janks.
- Not yet verified on a real Android or iOS device (Android/iOS native
  libraries ship with `sherpa_onnx`, but the first build there is untested).
