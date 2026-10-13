# Kairos

Kairos is a clock and personal-productivity plugin for the Omarchy bar. The QML plugin keeps mutable application state in `Service.qml`, exposes a standalone panel in `Panel.qml`, and uses `BarWidget.qml` for the compact clock and optional focus timer.

## Features

- **Day:** six-week calendar grid, `khal` event details, meeting/location links, notifications, and Obsidian daily-note tasks.
- **Focus:** Pomodoro and Flowtime timers, breaks, interruptions, task selection, and session history.
- **Plan:** four-quadrant Eisenhower board, task editing/completion, drag-and-drop, and completed-task search/restore.
- **Stats:** daily summaries, Monday–Sunday week, focus heatmap, streaks, and filterable session history.
- **Markets:** reorderable watchlist, quote and chart views, search, and fiat/crypto/unit conversion. Public data sources are keyless; no market credentials are required.
- **Social:** unread conversations, recent calls, ringing actions, message history/composer, and account filters for enabled local adapters.
- **Email:** IMAP unread inbox, thread view, mark-as-read, reply/reply-all/forward, new messages, and SMTP sending.
- **Settings:** Focus, Flowtime, Calendar, Obsidian, Markets, Social, Email, Bar, Stats, Shortcuts, Notifications, and Data.

## Social adapters

Kairos does not impersonate the proprietary clients or protocols for Telegram, WhatsApp, Signal, Discord, or Matrix. Social integrations are optional and are read from the local `kairos-social-bridge` executable. If it is missing, Kairos reports that the bridge is unavailable; it does not create sample messages or calls.

The included `scripts/social-bridge` is a bounded JSON wrapper. A local adapter is expected to implement these command forms and return JSON:

```text
kairos-social-bridge capabilities --json
kairos-social-bridge snapshot --json
kairos-social-bridge send --json --platform PLATFORM --account-id ID --chat-id ID
kairos-social-bridge mark-read --platform PLATFORM --account-id ID --chat-id ID
kairos-social-bridge call answer|decline --platform PLATFORM --call-id ID
```

`capabilities --json` returns an object with a `platforms` map (boolean values or `{ "available": true|false }` records) and an optional `accounts` array. `snapshot --json` returns `accounts` and an `events` array. Message events need `id`, `platform`, `accountId`, `kind: "message"`, a timestamp, and chat/sender metadata; call events use `kind: "call"` plus a `callState` such as `ringing`, `missed`, `incoming`, or `outgoing`. The wrapper passes a JSON `{ "text": "..." }` payload on stdin for `send`. Action responses must include `{ "ok": true }` on success. Install only an adapter appropriate for the accounts, permissions, clients, and protocols on the machine. Kairos exposes unavailable/error states for unsupported actions and does not claim service compatibility that has not been verified locally.

## Email and credentials

Email is optional. Add an account under **Settings → Email**, enter the provider's server settings, then save its app password. Passwords are passed to `secret-tool` through standard input and stored under the `io.github.yks777.kairos.email` Secret Service attributes. They are never written to `state.json` or command-line arguments. If `secret-tool` or an unlocked Secret Service keyring is unavailable, Kairos reports the problem and cannot connect or send.

The included Python helper uses TLS for IMAP (port 993, or STARTTLS on 143) and SMTP (implicit TLS on 465 or STARTTLS on 587). Configure the exact host, port, and username your provider documents; provider compatibility has not been tested for every service. Kairos keeps at most 20 unread messages per account in memory per fetch, polls/uses IMAP IDLE where supported, and retains up to 100 recent inbox entries for the current session. Thread grouping uses message references when available, with a message-ID fallback. Attachment names are shown as metadata only; attachment files are not downloaded. Email preview notifications are disabled by default.

## Notification sound

The global **Notifications → Sound** setting controls an additional local system-theme sound. Kairos tries `pw-play` or `paplay` with the installed Freedesktop message sound, then `canberra-gtk-play` with the `message-new-instant` event. Sound is best-effort and remains silent if neither a compatible player nor a theme sound is installed; the desktop notification itself is sent separately through `omarchy-notification-send`.

## Obsidian writes

Obsidian is off until enabled and given an absolute vault path. Selecting a date is the explicit action that opens or creates its daily note; reading today's tasks does not open Obsidian. Static templates are read as plain text; Templater is never invoked. `scripts/obsidian-write` writes note data received on standard input using a temporary file and atomic replacement.

## Markets data

Markets uses public, keyless endpoints: Yahoo Finance for listed-symbol charts/search, Binance public spot endpoints for crypto quotes/charts, CoinGecko for coin metadata/search, and open.er-api.com for fiat conversion rates. Market caches are under `~/.cache/omarchy/kairos/markets/`; failed sources remain visibly unavailable/stale without blocking other views.

## State and validation

Plugin state is stored at `$XDG_DATA_HOME/kairos/state.json`, falling back to `~/.local/share/kairos/state.json`. Email secrets are separate in Secret Service. For the full source/install procedure and state-file safety rules, read [`.Agents.md`](.Agents.md).

Run the available local checks with:

```sh
node --test tests/
python3 -m unittest discover -s tests -p 'test_*.py'
```

The workspace may not include Omarchy, `qmllint`, or a graphical session. Record unavailable manifest/runtime/visual checks as unverified; do not claim they passed. The manifest keeps `omarchy.clonedFrom` during development; remove it only before publication.
