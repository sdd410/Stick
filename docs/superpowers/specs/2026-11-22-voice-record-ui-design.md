# Voice recording: live voice animation + smaller stop square (short design)

Approved by the user on 22 Nov 2026 from the mockup at https://claude.ai/artifact/RAs7gqTYakDxhKxGm3DJzN (version 2).

## Why
On the voice recording screen nothing visibly reacts to your voice (the growing circle is faint), so you can't tell if the mic hears you. The stop square fills the whole 72dp button and looks oversized.

## Design
- **Mic:** a 72dp circle (lime at ~22% alpha) with a 32dp mic icon. Around it, a 2px lime ring (~110dp box) whose opacity (0.15 → 0.85) and scale (0.72 → 1.0) follow the current voice level. Hidden when the platform asks for reduced motion (`MediaQuery.disableAnimations`).
- **Live bars:** below the mic, a row of 30 bars (4dp wide, 3dp gap, rounded), max height 56dp, min 4dp. Each new level reading (every 100ms from `ClipRecorder.level`, 0..1) is appended on the right and the oldest drops off the left. The oldest ~10 bars are drawn at lower opacity. Silence = flat 4dp dots.
- **Stop button:** while recording, the 72dp button stays a lime circle with a 28dp dark (`StickColors.bg`) rounded square (radius 6) centered in it. Before recording: plain lime circle (unchanged). The progress ring is unchanged. Applies to voice and video.
- Video recording is otherwise unchanged.

## Approaches
- **Bars + pulsing ring (picked)**: obvious feedback, familiar from voice-memo apps.
- Only a bigger growing circle: still subtle, and silence looks the same as "not started".
- Only bars: works, but the user liked the ring with the smaller mic.

## Non-goals
No change to recording logic, limits, file format, or the level mapping (dBFS -50..0 → 0..1).
