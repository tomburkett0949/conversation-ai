# Security and privacy
- All audio, transcripts and AI processing stay on the device. No analytics, no cloud AI calls.
- Public GitHub repo: contains no personal data. Secrets (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8) live only in GitHub Actions secrets; Team ID and bundle prefix are repository variables. CI logs print no personal data.
- App Store Connect key has Admin role: rotate it if ever exposed. Delete any desktop copies of the .p8 file.
- Recording consent: the record screen reminds the user to get permission before recording others. UK law and university rules still apply; a consent log is not yet built.
- Recordings sit in the app sandbox, protected by device encryption/passcode.
