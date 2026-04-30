# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShelfPlayer is a native iOS app (Swift 6, iOS 26+) for listening to audiobooks and podcasts from self-hosted [Audiobookshelf](https://www.audiobookshelf.org/) servers. It uses SwiftUI, SwiftData, and AVFoundation.

## Build & Run

The project uses **XcodeGen** to generate the Xcode project from `project.yml`.

```bash
# Generate the Xcode project (required after changing project.yml or pulling changes)
xcodegen generate

# Build from command line
xcodebuild -scheme ShelfPlayer -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### First-time setup

1. Copy `Configuration/Debug.xcconfig.template` to `Configuration/Debug.xcconfig`
2. Edit with your development team ID, bundle prefix, and feature flags
3. Run `xcodegen generate`

### Configuration flags

- `ENABLE_CENTRALIZED` — enables features requiring a paid developer account (app groups, iCloud, Siri, CarPlay). Without it, the app uses `FREE_DEVELOPER_ACCOUNT.entitlements`.
- Build number is auto-set from git commit count via a post-compile script.

## Architecture

### Module dependency graph

```
ShelfPlayer (app)
├── ShelfPlayerKit (framework) — data models, networking, persistence
│   ├── RFKit (SPM, internal utility lib)
│   ├── SwiftSoup (HTML parsing)
│   └── SocketIO (real-time updates)
├── ShelfPlayback (framework) — AVFoundation audio engine
│   └── ShelfPlayerKit
├── ShelfPlayerMigration (framework) — version migration
│   └── ShelfPlayerKit
└── ShelfPlayerWidgets (app extension) — WidgetKit widgets
    └── ShelfPlayerKit
```

### Key layers

- **ShelfPlayerKit** (`/ShelfPlayerKit/`): Core framework. Contains REST API client (actor-based), SwiftData persistence with subsystem pattern (AuthorizationSubsystem, ProgressSubsystem, DownloadSubsystem, etc.), and data models. No SwiftUI dependency.
- **ShelfPlayback** (`/ShelfPlayback/`): Audio playback engine (AudioPlayer), session management, progress reporting to server, Now Playing integration.
- **App** (`/App/`): SwiftUI UI layer. Uses `@Observable` ViewModels. Key singletons: `Satellite` (navigation/UI coordinator), `PlaybackViewModel`, `ConnectionStore`.
- **WidgetExtension** (`/WidgetExtension/`): Home screen and lock screen widgets sharing data via app group.

### Patterns

- **@Observable + @MainActor** for ViewModels (Swift 6 concurrency)
- **Subsystem pattern** in persistence: each domain (progress, downloads, bookmarks, etc.) is a separate subsystem class under `ShelfPlayerKit/Persistence/Subsystems/`
- **Actor-based API client** for thread-safe networking
- **Combine** for event publishing from playback layer to UI
- Shared state between app and widgets via **UserDefaults suite** (app group)

### Data model hierarchy

```
Item (base)
├── PlayableItem (adds duration, size)
│   ├── Audiobook
│   └── Episode
└── Podcast
```

## Design & Code Style

- **4-unit spacing system** for all UI layout
- UI should look and feel like a native Apple-made iOS app — minimal, clean, familiar
- Write minimal, lean, expressive Swift 6 code using modern language features: async/await, actors, Combine, @Observable, Sendable
- All "backend" code (networking, persistence, data models) belongs in the relevant frameworks (ShelfPlayerKit, ShelfPlayback), not in the app target
- The app target contains only SwiftUI views, ViewModels, and navigation

## Tests

Both test targets hit the local Audiobookshelf dev server at `http://localhost:3333` (credentials: `root` / `root`). Make sure the server is running and seeded with the public-domain audiobook collection (Pride and Prejudice, Alice in Wonderland, …) before running tests — see [Local Audiobookshelf dev server](#local-audiobookshelf-dev-server) below.

```bash
# Run unit tests (ShelfPlayerKit integration tests against http://localhost:3333 root:root)
xcodebuild test -scheme ShelfPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShelfPlayerKitTests ENABLE_USER_SCRIPT_SANDBOXING=NO

# Run UI tests (drives the welcome flow against http://localhost:3333)
xcodebuild test -scheme ShelfPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShelfPlayerUITests ENABLE_USER_SCRIPT_SANDBOXING=NO

# Run all tests
xcodebuild test -scheme ShelfPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  ENABLE_USER_SCRIPT_SANDBOXING=NO
```

- **ShelfPlayerKitTests**: Swift Testing-based integration tests against the local server. Cover API client auth (login, status, ping, refresh), library/genre fetching, search, `me`/`authorize`, and pure-logic `ItemIdentifier` round-trips.
- **ShelfPlayerUITests**: XCTest-based UI tests for the welcome flow, connection setup, tab navigation, search, audiobook detail, playback start, bookmark/finished controls, and offline mode. The test bundle defines a `LocalServer` fixture (endpoint, credentials, seeded titles) at the bottom of `ShelfPlayerUITests.swift`.
- Fixture data for previews lives in `ShelfPlayerKit/Fixtures/`.

### Test isolation

UI tests rely on two debug-only launch environment variables wired in `ShelfPlayerApp.init()` (gated behind `#if DEBUG` so they cannot ship in release):

- `WIPE_CONNECTIONS=YES` — synchronously deletes every keychain entry the app owns at launch, so the test starts on the welcome screen.
- `FORCE_OFFLINE_MODE=YES` — forces offline mode after the initial availability probe completes, so tests with a logged-in connection drop straight onto the offline panel.

`XCUIApplication.launchForUITesting(wipeConnections:forceOfflineMode:)` is the entry point — `ConnectionFlowTests` and `OfflineModeTests` opt into wiping; `UserFlowTests` reuses an existing connection so the API content cache is warm.

Prefer **a fresh simulator clone** when you want stronger isolation than the keychain wipe (file system, UserDefaults, downloads):

```bash
# Clone, run tests against the clone, then delete it
udid=$(xcrun simctl clone "iPhone 17 Pro" "ShelfPlayer Tests")
xcrun simctl boot "$udid"
xcodebuild test -scheme ShelfPlayer -destination "platform=iOS Simulator,id=$udid" \
  ENABLE_USER_SCRIPT_SANDBOXING=NO
xcrun simctl shutdown "$udid"
xcrun simctl delete "$udid"
```

ATS already allows arbitrary loads (`NSAllowsArbitraryLoads = YES` in `App/Info.plist`), so plain HTTP to `localhost` works from the simulator.

### Offline mode tests

`OfflineModeTests` covers two scenarios:

- **Welcome wins without connections**: launching with `WIPE_CONNECTIONS=YES` and `FORCE_OFFLINE_MODE=YES` should still show the welcome screen — no connections means offline mode is moot.
- **Offline panel + recovery**: log in to localhost on a wiped simulator, terminate, relaunch with `FORCE_OFFLINE_MODE=YES`, expect the offline panel, tap the toolbar **Go online** button, expect the tab bar to return.

The toolbar **Go online** button is selected via `app.navigationBars["Offline"].buttons["Go online"]` because the offline panel renders the same label twice (toolbar + body row).

## Local Audiobookshelf dev server

A local Audiobookshelf server runs at `http://localhost:3333` (credentials: `root` / `root`). Source checkout lives at `/Users/rasmus/Desktop/Development/audiobookshelf` — useful for verifying what the ABS API actually returns when reasoning about client behavior.

```bash
# Log in and capture an access token
TOKEN=$(curl -s -X POST http://localhost:3333/login \
  -H "Content-Type: application/json" \
  -d '{"username":"root","password":"root"}' | python3 -c 'import json,sys; print(json.load(sys.stdin)["user"]["accessToken"])')

# List libraries
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3333/api/libraries

# Personalized home shelves for a library (what `/personalized` returns is the
# ground truth for what rows can appear in the iOS home screen)
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:3333/api/libraries/<LIBRARY_ID>/personalized
```

Prefer this local server over the public `audiobooks.dev` demo when gauging API shapes — you can mutate state (download, play, scan) without affecting anyone else.

## Localization

The app supports multiple languages. Localized strings are in `.xcstrings` files. See `Localization.md` for contributing translations.

**Do not modify `.xcstrings` files unless specifically tasked to.** Xcode manages these files automatically when source code references new localized strings, and manual edits can clobber translations or auto-generated metadata.
