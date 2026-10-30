# Architecture — Ask Jeeves

Private, single-user, on-device iOS/iPadOS app (Swift/SwiftUI, iOS 17+). No server, no accounts, no recurring cost.

## Data flow
Record (AVAudioEngine) → m4a file + live on-device speech recognition (SFSpeechRecognizer, en-GB, on-device only) → JSON sidecar (`SavedMeeting`) → Summary / flashcards (Apple on-device Foundation Models, iOS 26 + Apple Intelligence; keyword fallback) → Search / Ask (keyword + NLEmbedding semantic fallback) → Actions dashboard.
Import: file → AVAssetExportSession (m4a) → SFSpeechURLRecognitionRequest (on-device) → same JSON sidecar → auto-summary.

## Storage
App Documents/Recordings: `Name.m4a` + `Name.json`. Action ticks in UserDefaults. Nothing leaves the device.

## Build and delivery
xcodegen (`project.yml`) → GitHub Actions macos-15 → unsigned archive → export with App Store Connect API key (automatic signing) → TestFlight. A second workflow checks TestFlight status and manages the internal tester group.

## Not built yet
iCloud sync, speaker labels (needs a diarisation model), SpeechAnalyzer engine, widget / Lock Screen control, PC "boost" server and Windows app.
