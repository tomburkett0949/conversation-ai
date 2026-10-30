# COMPETITOR ANALYSIS — Conversation AI
Researched 30 Oct 2026 from public pages only (no private APIs, no scraping behind logins).
**Evidence levels:** [W] = read on a fetched web page this session; [K] = general product knowledge, NOT re-verified today (treat as unconfirmed until Phase 1b).

## 1. Products covered
| Product | Capture | Best feature | Weak spot / complaint | Evidence |
|---|---|---|---|---|
| Otter.ai | Bot (auto-joins) | Real-time transcript + meeting Q&A; cheap annual plan | Free tier 300 min/mo, 30 min/convo cap; **class-action privacy suit** (non-account-holders recorded, voiceprints) | [W] |
| Fireflies.ai | Bot or Chrome extension | 100+ languages; big searchable call library; topic tracking | Free tier limits storage/summaries; **two BIPA suits** over speaker recognition/voiceprints | [W] |
| Fathom | Bot, bot-free in beta | Most generous free plan (unlimited recordings + summaries); fast summaries | Team plans need 2+ users; bot-free still beta | [W] |
| Granola | **Bot-free** (device audio) | Your typed notes + AI-enhanced notes, no bot in call | Free tier keeps 30 days history; you must still tell others you record | [W] |
| tl;dv | Bot | Cross-meeting search, clips/highlights, CRM links | Pricing not verified | [W partly] |
| Read AI | Bot | Objective meeting scoring / coach; CRM integrations | Free tier 5 transcripts/mo; video playback gated to Enterprise | [W] |
| Zoom / Teams Copilot / Gemini in Meet | Built-in | Zero extra vendor; works inside platform | Locked to that platform; paid-tier gating | [W] |
| Krisp | Bot-free, system-audio | Noise/echo removal at the source | — | [K] |
| Avoma, Fellow, MeetGeek, Notta, Circleback, Jamie, Sembly, Grain | mixed | Avoma: conversation intelligence; Fellow: agendas + follow-through; Circleback/Jamie: bot-free notes + automations; Grain: clips | not checked | [K] |

## 2. What each does unusually well (to learn from)
- **Otter** — live transcript you can ask questions of mid-meeting.
- **Granola** — human notes first, AI enhances; no bot; feels like a notepad.
- **Fireflies** — organisation: library, topics, search across calls.
- **Fathom** — speed and clean summaries; generous free tier sets price expectations.
- **tl;dv** — clips/moments shared as short snippets.
- **Krisp** — audio cleaned before it is transcribed.
- **Read AI** — objective, observable meeting metrics.
- **Fellow** — preparation and follow-through (agenda → actions).

## 3. Common weaknesses worth exploiting
1. **Consent & privacy** — live lawsuits against Otter and Fireflies show auto-join bots and voiceprints are legally risky [W]. Consent is pushed onto the account holder.
2. **Per-meeting islands** — most tools summarise one meeting; cross-meeting reasoning is thin.
3. **Cost** — free tiers are capped; AI is cloud-metered, so price scales with use.
4. **Black-box claims** — summaries rarely link every claim to transcript evidence.
5. **Cloud-only** — audio and transcripts leave your device by default.

## 4. Lessons from the lawsuits (design rules, not legal advice)
- Get participant consent before recording; declining must block recording.
- Non-users are covered too; disclosure must reach them.
- Don't email transcripts to people who didn't attend.
- **No voiceprints by default**; any speaker recognition is opt-in, disclosed, with retention stated. (Matches your brief, section 14.)
- Log when consent was given. Have a solicitor review before any public release.

## 5. Sources
- Teamshift guide: https://teamshift.io/guides/ai-meeting-assistant
- tl;dv on recorder lawsuits (vendor blog, treat as one-sided): https://tldv.io/blog/ai-meeting-recorder-lawsuits/
- Other pages found, not yet read: simular.ai, rock.so, get-alfred.ai, meetily.ai, uctoday.com Otter coverage
