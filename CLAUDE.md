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
xcodebuild -scheme ShelfPlayer -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'
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

## No Tests

There is no test target. The project uses SwiftUI `#Preview` blocks and fixture data in `ShelfPlayerKit/Fixtures/`.

## Localization

The app supports multiple languages. Localized strings are in `.xcstrings` files. See `Localization.md` for contributing translations.
