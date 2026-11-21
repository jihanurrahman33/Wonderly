"""Generates Wonderly's sound effects and background music as 16-bit mono WAV.

Run: python3 tool/generate_audio.py
Everything is synthesised from sine waves, so there are no third-party samples
and no licensing concerns. Output goes to assets/audio/.
"""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def note(freq, dur, vol=0.5, attack=0.01, release=0.12, harmonics=(1.0, 0.3, 0.1)):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) if attack else 1.0
        tail = dur - t
        if tail < release:
            env *= max(0.0, tail / release)
        s = sum(a * math.sin(2 * math.pi * freq * (k + 1) * t) for k, a in enumerate(harmonics))
        out.append(vol * env * s / sum(harmonics))
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def save(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


C4, D4, E4, G4, A4 = 261.63, 293.66, 329.63, 392.00, 440.00
C5, D5, E5, G5, A5, C6 = 523.25, 587.33, 659.25, 783.99, 880.00, 1046.50

# Happy rising arpeggio.
save("correct.wav", note(C5, 0.10) + note(E5, 0.10) + note(G5, 0.22, release=0.2))
# Gentle, low and friendly: never scary.
save("wrong.wav", note(G4, 0.14, vol=0.35) + note(E4, 0.26, vol=0.35, release=0.2))
# Short tap.
save("tap.wav", note(A5, 0.05, vol=0.3, release=0.04))
# Quiz finished.
save("complete.wav", note(C5, 0.12) + note(E5, 0.12) + note(G5, 0.12) + note(C6, 0.40, release=0.3))
# Badge sparkle.
save("badge.wav", note(G5, 0.08) + note(C6, 0.08) + note(E5 * 2, 0.08) + note(G5 * 2, 0.45, release=0.35))

# Soft looping lullaby in C major pentatonic, 16 seconds, ends on the tonic so
# the loop is seamless.
melody = [
    (C5, 0.5), (E5, 0.5), (G5, 1.0), (E5, 0.5), (D5, 0.5), (C5, 1.0),
    (A4, 0.5), (C5, 0.5), (D5, 1.0), (E5, 0.5), (G5, 0.5), (E5, 1.0),
    (D5, 0.5), (C5, 0.5), (A4, 1.0), (G4, 0.5), (A4, 0.5), (C5, 1.0),
    (E5, 0.5), (D5, 0.5), (C5, 1.5), (silence, 0.5),
]
lead = []
for f, d in melody:
    lead += silence(d) if callable(f) else note(f, d, vol=0.22, release=0.25, harmonics=(1.0, 0.15))
bass = []
for f in (C4 / 2, G4 / 2, A4 / 2, G4 / 2) * 2:
    bass += note(f, 2.0, vol=0.12, attack=0.1, release=0.4, harmonics=(1.0,))
save("music.wav", mix(lead, bass))
print("Wrote", sorted(p.name for p in OUT.glob("*.wav")))
