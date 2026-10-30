# FEATURE MATRIX — Conversation AI
Legend: ✔ strong · ◐ partial · ✘ absent · ? unverified. Competitor columns are from [W]/[K] notes in COMPETITOR_ANALYSIS.md; "Ours" = plan, nothing built yet.

| Capability | Otter | Fireflies | Fathom | Granola | tl;dv | Read AI | Ours (plan) |
|---|---|---|---|---|---|---|---|
| Live transcript | ✔ | ◐ | ? | ✔ | ? | ? | ✔ fast draft + background refine |
| Bot-free capture | ✘ | ◐ | ◐ beta | ✔ | ✘ | ✘ | ✔ default; bot optional later |
| User notes + AI notes | ◐ | ✘ | ✘ | ✔ | ✘ | ✘ | ✔ originals never overwritten |
| Summaries / actions | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ with evidence links |
| Cross-meeting Q&A | ◐ | ◐ | ◐ | ◐ | ✔ | ? | ✔ core feature |
| Decision tracking + conflict flags | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✔ |
| Global action dashboard | ◐ | ◐ | ◐ | ✘ | ◐ | ◐ | ✔ |
| Clips / highlights | ◐ | ◐ | ✔ | ✘ | ✔ | ◐ | ✔ |
| Objective meeting analytics | ◐ | ✔ | ◐ | ✘ | ◐ | ✔ | ✔ observable metrics only |
| Audio enhancement | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✔ before transcription |
| Local / on-device AI | ✘ | ✘ | ✘ | ◐ | ✘ | ✘ | ✔ RTX 3080 server |
| Pre-meeting brief + agenda | ◐ | ✘ | ✘ | ✘ | ✘ | ◐ | ✔ |

## Adopt / reject
**Adopt:** Otter live Q&A · Granola notes model · Fireflies library/search · Fathom clips and speed · Krisp-style cleanup · Read AI objective metrics · Fellow prep/follow-through.
**Reject:** auto-joining bots by default · voiceprints without opt-in · emotion/honesty/personality scoring (unreliable) · auto-emailing attendees · cloud upload by default.

## Five original improvements
1. **Evidence-linked everything** — every summary line, action and decision carries a clickable transcript timestamp; unsupported claims are not shown.
2. **Decision conflict alerts** — a new meeting that contradicts an earlier decision is flagged with both quotes.
3. **Promise tracker** — "what have I committed to that isn't done?" across all meetings, with the exact moment you agreed.
4. **Private-by-default AI** — audio, transcripts and models stay on your RTX 3080; phones talk to your own PC over an encrypted link; zero recurring AI cost.
5. **Consent ledger** — each recording stores who was told, how, and when; declining stops capture. Turns the lawsuit risk into a feature.
6. *(bonus)* **Memory timeline per project** — first mention → changes → outcome, built only from transcript evidence.

## Stack candidates to benchmark in Phase 4 (from Oct 2026 Open ASR Leaderboard page [W])
Lower WER is better; RTFx is on an H200, so speeds are not RTX 3080 numbers.
| Model | Licence | WER | Notes |
|---|---|---|---|
| Whisper large-v3 (via faster-whisper) | MIT | 7.16 | 99 languages, proven, word timestamps via WhisperX |
| Whisper large-v3-turbo | MIT | 7.64 | ~6 GB VRAM, faster |
| Parakeet TDT 0.6B v2/v3 | CC-BY-4.0 | 6.02 / 6.18 | very fast, word timestamps, English / 25 European |
| Qwen3-ASR-1.7B | Apache 2.0 | 5.40 | best accuracy listed; needs separate aligner |
| Diarisation: pyannote 3.1 | MIT code, HF terms | ~11–27% DER by dataset | 2–4 GB VRAM; safest default |

**Planned three pipelines:** (A) faster-whisper large-v3 + pyannote · (B) Parakeet v3 + pyannote · (C) Qwen3-ASR + pyannote (or WhisperX alignment). Leaderboard scores can mislead, so I'll test on your own UK-English clips.
