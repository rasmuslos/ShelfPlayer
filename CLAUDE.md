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

```bash
# Run unit tests (ShelfPlayerKit integration tests against https://audiobooks.dev demo:demo)
xcodebuild test -scheme ShelfPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShelfPlayerKitTests ENABLE_USER_SCRIPT_SANDBOXING=NO

# Run UI tests
xcodebuild test -scheme ShelfPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShelfPlayerUITests ENABLE_USER_SCRIPT_SANDBOXING=NO

# Run all tests
xcodebuild test -scheme ShelfPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  ENABLE_USER_SCRIPT_SANDBOXING=NO
```

- **ShelfPlayerKitTests**: Swift Testing-based unit tests that hit the live demo server at `https://audiobooks.dev` (credentials: `demo`/`demo`). Tests cover API client auth, library fetching, search, and ItemIdentifier logic.
- **ShelfPlayerUITests**: XCTest-based UI tests for connection flow, navigation, and content browsing.
- Fixture data for previews lives in `ShelfPlayerKit/Fixtures/`.

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
