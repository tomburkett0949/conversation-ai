# DECISIONS (Tom, 30 Oct 2026)
1. **Mobile-first, standalone.** Main use is iPad and iPhone. The apps must record, transcribe, summarise, search and manage actions with NO PC connection.
2. **Otter-style simplicity.** App opens to a home screen where the user chooses what to do (Record, Import, Meetings, Ask AI, Actions).
3. **PC is optional.** The RTX 3080 PC is a "boost" for heavier/higher-accuracy processing when reachable; never required.
4. **Native Swift/SwiftUI** (one codebase for iPhone + iPad) is the working plan; confirm in the mobile framework comparison.
5. **Sync via iCloud** between iPhone and iPad (no always-on server).
6. Benchmarks: on-device speech + language models on iPad/iPhone first; 3080 pipelines second.
7. **Use case (30 Oct):** Tom's own rugby coaching course and university lectures (long recordings, mostly one speaker, technical vocabulary). Personal use first.
8. **Zero extra cost.** New PUBLIC GitHub repo (free Mac build minutes); build via GitHub Actions to TestFlight, same pattern as the Game Day apps (xcodegen + xcodebuild + App Store Connect API key). Needs secrets ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 and variables TEAM_ID, BUNDLE_PREFIX. No recordings or personal data ever committed.
