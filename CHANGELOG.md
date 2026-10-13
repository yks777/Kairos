# Changelog

## 1.0.0

- Added the Kairos plugin foundation, clock and conditional timer bar widget, standalone panel shell, reusable UI primitives, state persistence, and pure logic tests.
- Implemented the Day view with a fixed six-week month grid, `khal` calendar loading and monthly cache, event details and meeting links, persistent event notifications, and Obsidian daily-note tasks.
- Added the Focus view with Pomodoro and Flowtime transitions, pause/resume, interruptions, breaks, timer notifications, IPC controls, and session history.
- Added the Plan view with a four-quadrant task matrix, editing, completion, confirmed deletion, drag-and-drop, and a searchable completed-task popup.
- Implemented Stats with live-aware daily totals, the current Monday–Sunday week, a 12-week heatmap, streaks, and date/technique-filtered session history.
- Implemented Markets with a persistent reorderable watchlist, Yahoo Finance and Binance quote/chart sources, CoinGecko search and metadata, currency selection, and bidirectional fiat/crypto/unit conversion.
- Added secure cached `fetch-rates` and `fetch-crypto` scripts for public keyless APIs, plus pure tests for market, converter, number-format, and heatmap logic.
- Implemented the Social and Settings panel views. Social uses an optional, documented `kairos-social-bridge` adapter and reports unavailable services rather than inventing messages or calls.
- Added Email IMAP/SMTP account configuration, unread/thread views, mark-as-read, reply/reply-all/forward and compose flows. Email passwords use Secret Service through `secret-tool`, never `state.json` or argv.
- Added atomic Obsidian note writes through `scripts/obsidian-write`; updated `scripts/email-fetch`, README, agent guidance, and Social/Email model tests.
- Added Social, Settings, refresh, and Email-send service/IPC entry points while preserving the standalone panel and the existing Stats/Markets code paths.
