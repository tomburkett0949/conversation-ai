# TestFlight deployment
Push to `main` (changes outside docs/, config/, tools/) runs "Build and send to TestFlight" (about 10 min), then Apple processes the build (about 10 min more). Build number = GitHub run number.
Secrets: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8. Variables: TEAM_ID, BUNDLE_PREFIX.
"Check TestFlight status" (manual) prints build state and keeps the internal group and testers in order.
Internal builds expire after 90 days: push any change to refresh.
