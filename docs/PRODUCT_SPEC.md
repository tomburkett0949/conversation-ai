# PRODUCT SPEC v0.1 — Conversation AI (working name; set in config/brand.config.json)
Status: draft for Tom's review. Nothing here is built or tested yet.

## 1. One-line product
A private, phone-first AI memory for conversations: record anywhere, get accurate notes, and ask questions across everything you've ever discussed. Works fully on iPhone and iPad with no PC.

## 2. Principles
1. **Standalone on device.** Record, transcribe, label speakers, summarise, search and ask AI with no network. (Tom, 30 Oct.)
2. **Simple like Otter.** Home screen, big choices, no clutter.
3. **Private by default.** Audio and transcripts stay on your devices (iCloud sync only). No third-party upload without an explicit switch.
4. **Evidence or silence.** Every AI claim links to the transcript moment. If unsupported, it isn't shown. Missing info (owner, deadline) stays blank, never invented.
5. **Consent first.** Visible recording indicator, consent log, no voiceprints unless opted in.
6. **PC is a bonus.** When reachable, the RTX 3080 re-processes recordings for higher accuracy and heavy cross-meeting analysis.

## 3. Primary devices
iPhone 17 Pro Max (phone layout), iPad Air M3 (three-panel layout: Meetings | Transcript | AI). Windows app is a later companion (library + PC boost server).

## 4. Home screen (what you can choose)
Record · Import (audio/video) · Meetings · Ask AI · Actions · Search. Secondary: Projects, People, Decisions, Settings.

## 5. Core flows
**Record:** tap Record → red indicator + consent prompt → live transcript (fast draft) → optional typed notes → stop → "Processing" steps (Preparing → Enhancing → Transcribing → Speakers → Analysing → Indexing → Done) → refined transcript replaces draft.
**Meeting screen tabs:** Summary · Transcript · Notes (Original / AI-enhanced, both kept) · Actions · Decisions · Questions · Highlights · Ask AI. Tap a line to jump audio; playback highlights current line.
**Ask AI:** natural questions, answered with quoted evidence and tappable timestamps. Scope: this meeting, a project, a person, or everything.
**Actions dashboard:** Mine · Assigned to others · Due soon · Overdue · Done · Unassigned; each links to meeting + timestamp.
**Decisions:** log with who/when/why/evidence; contradiction flags across meetings.
**Timeline:** per project/topic, first mention → changes → outcome.
**Pre-meeting brief / post-meeting pack:** previous summary, open actions, unresolved questions → after: summary, follow-up email draft, next agenda. Always editable; nothing sent automatically.
**Clips:** pick a range or "clip the pricing discussion" → shareable audio snippet.

## 6. Feature tiers
**MVP (v1, on phone/iPad):** record, import, live+refined transcript, speaker labels & rename, custom vocabulary, summary/key points/decisions/actions with evidence, own notes + AI notes, per-meeting Ask AI, keyword + semantic search, actions dashboard, offline recording with safe resume, iCloud sync, export/delete controls, consent log.
**v1.5:** cross-meeting memory, decisions conflict flags, timeline, projects/people views, clips, analytics (talk time, questions, interruptions — objective only), meeting effectiveness report, pre/post-meeting packs, agent suggestions (propose-only).
**v2:** PC boost server, Windows app, translation, optional meeting bots (Zoom/Teams/Meet), knowledge graph if benchmarks justify it, Android.

## 7. Explicitly NOT doing
Emotion/honesty/personality scoring · silent voiceprints · auto-sending emails · auto-joining bots by default · any rugby features.

## 8. On-device AI (to be proven by benchmarks)
| Job | Candidate (unverified on-device) |
|---|---|
| Speech-to-text | WhisperKit (open-source Whisper on Core ML) · Apple's built-in speech framework · Parakeet via Core ML |
| Speaker labels | open-source diarisation ported to Core ML (to verify) |
| Audio cleanup | Apple voice processing + open-source noise suppression |
| Summaries / extraction / Q&A | Apple on-device language model (iOS 26+, if available to third-party apps on 17 Pro Max) · small open model via MLX/Core ML as fallback |
| Search | on-device embeddings + SQLite full-text |
Selection rule: pick by measured accuracy, speed, battery, heat and memory on iPhone 17 Pro Max and iPad Air M3.

## 9. Data (SQLite on device, migrations from day one)
Meetings, recordings, speakers, people, segments, words, notes (original + AI), summaries, actions, decisions, questions, topics, projects, highlights, embeddings, AI chats, consent log, settings. Sync via iCloud (CloudKit/file sync, to decide).

## 10. Costs
Target £0 recurring. Known one-off: Apple Developer membership (already held). Cloud Mac or GPU only with your approval.

## 11. Success checks (per phase: build → run → test → fix → verify)
Record 60 min offline without loss · transcript within agreed accuracy on UK-English test clips · every AI claim has a working timestamp link · search returns semantic matches · app usable one-handed on iPhone, no scrolling surprises on iPad.

## 12. Open questions for Tom
1. Confirm Swift/SwiftUI native (recommended for background recording reliability).
2. How were the Game Day apps built and uploaded to TestFlight (needed to reuse the route)?
3. Any 2–3 real UK-English recordings you can use for testing (your own/consented only)?
