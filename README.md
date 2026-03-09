# ShelfPlayer

**ShelfPlayer** is a powerful iOS application for listening to audiobooks and podcasts, designed for users with self-hosted [Audiobookshelf](https://www.audiobookshelf.org/) libraries. Built in **Swift 6** for **iOS 18+**, ShelfPlayer is fast, privacy-respecting, and deeply integrated with the Apple ecosystem.

> [!WARNING]
> ShelfPlayer does not include any media content. A running Audiobookshelf instance is required to use the app.

## Features

* **Unified audiobook and podcast app**: A single, native experience for audiobooks, podcasts, episodes, authors, narrators, series, collections, and playlists.
* **Multi-server support**: Works with multiple Audiobookshelf servers and libraries at the same time.
* **Flexible authentication**: Supports both username/password and OpenID sign-in.
* **Custom request headers**: Additional HTTP headers can be configured for advanced setups.
* **Listen Now**: Continue listening and discover content across connected libraries.
* **Global and library search**: Fast search across books, podcasts, people, series, and episodes.
* **Playback queues**: Includes both a main queue and an Up Next queue.
* **Chapter navigation**: Chapter-level controls are available directly in playback views.
* **Playback speed controls**: Combines quick presets with precise rate tuning.
* **Configurable skip intervals**: Skip forward and backward durations can be tailored to personal preference.
* **Sleep timer**: Supports both time-based and chapter-based timers, with Live Activity integration.
* **AirPlay and media controls**: Native integration with AirPlay and Apple system media controls.
* **Bookmarks with notes**: Save key moments with optional notes.
* **Progress synchronization**: Listening progress and sessions stay in sync with Audiobookshelf.
* **Listening history**: Detailed, item-level listening timelines are available.
* **Daily listening tracking**: Tracks listening time with optional daily goals.
* **Offline mode and downloads**: Downloaded content remains available when offline.
* **Automatic convenience downloads**: Background downloads cover Listen Now, podcast, and series content.
* **Collections and playlists**: Built-in tools for creating, editing, and organizing collections and playlists.
* **PDF viewer**: Opens attached PDF documents in-app.
* **Home Screen widgets**: Includes Start, Listen Now, and Listened Today widgets.
* **Live Activities and Dynamic Island**: Sleep timer controls stay accessible on Lock Screen and Dynamic Island.
* **Siri, App Intents, and Shortcuts**: Playback and automation workflows are fully integrated with Apple automation tools.
* **CarPlay support**: Library browsing and playback controls are available in CarPlay.
* **Spotlight integration**: Indexed content appears in system search with deep links back into the app.
* **Home Screen quick actions**: Common playback and search actions are available from the app icon.
* **Native iPhone and iPad interface**: Optimized layouts with customizable tabs, sorting, and filters.

## Download

<a href="https://apps.apple.com/app/apple-store/id6475221163?ct=GitHub" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;">
    <img src="https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us?releaseDate=1710288000" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;">
</a>

## Screenshots
| Audiobook | Podcast | Player | Other |
| --- | --- | --- | --- |
| <img src="/Screenshots/iOS%20Audiobook.png?raw=true" alt="Audiobook (iPhone)" width="200"/>       | <img src="/Screenshots/iOS%20Podcast.png?raw=true" alt="Podcast (iPhone)" width="200"/>        | <img src="/Screenshots/iOS%20Player.png?raw=true" alt="Player (iPhone)" width="200"/>    | <img src="/Screenshots/iOS%20Listen%20Now.png?raw=true" alt="Listen Now (iPhone)" width="200"/> 
| <img src="/Screenshots/iPadOS%20Audiobook.png?raw=true" alt="Audiobook (iPad)" width="200"/> | <img src="/Screenshots/iPadOS%20Podcast.png?raw=true" alt="Podcast (iPad)" width="200"/> | <img src="/Screenshots/iPadOS%20Player.png?raw=true" alt="Player (iPad)" width="200"/> | <img src="/Screenshots/iPadOS%20Podcast%20Home.png?raw=true" alt="Podcast Home (iPad)" width="200"/> |

## Sideloading

### Prebuilt Releases

Download the latest release from the [Releases](https://github.com/rasmuslos/shelfplayer/releases) page and install it using tools such as SideStore.

**Important limitations when sideloading:**

* Siri is not supported without a paid Apple Developer account due to entitlement restrictions.
* App extensions (e.g., Widgets) may not function correctly; it is recommended to remove them before sideloading.
* For background and technical details, see https://github.com/rasmuslos/ShelfPlayer/issues/20 and https://github.com/rasmuslos/ShelfPlayer/issues/4.

### Building from Source

To build ShelfPlayer using Xcode:

1. Install Xcode.
2. In the `Configuration/` directory, copy `Debug.xcconfig.template` and rename it to `Debug.xcconfig`.
3. Edit the file with values appropriate for your environment (e.g. development team ID, bundle prefix, feature flags).
4. Connect your iPhone and enable Developer Mode.
5. Open the project in Xcode, select your device, then build and run the app.

> [!NOTE]
> The `Debug` configuration is used by default.

## Contributing

Contributions are welcome. To contribute:

1. Fork the repository.
2. Make your changes in a new branch.
3. Open a pull request.

If you're interested in helping translate ShelfPlayer, see the [Localization Guide](https://github.com/rasmuslos/ShelfPlayer/blob/main/Localization.md) for instructions on how to contribute a translation.

### AI / Vibe coding

I absolutely see the value in using AI to speed up development and automate tedious tasks. However, I don’t see much value in AI-generated pull requests. I can use tools like Codex myself (even the free version) and iterate with the AI interactively, which is usually faster and more efficient.

For that reason, please avoid submitting pull requests that only contain AI-generated code. Instead, feel free to open an issue describing the idea or improvement. If you’d like, you can also include the prompt you used.

I simply don’t have more time to review AI-generated pull requests than I do to use AI tools directly in my own workflow.

## License

ShelfPlayer is licensed under the **Mozilla Public License 2.0** with the **Commons Clause**.

You are allowed to:

* View, modify, and build the source code for personal use.
* Submit changes or improvements via pull requests.

You are **not allowed** to:

* Distribute ShelfPlayer in binary form (including on the App Store or through other app distribution platforms).

Prebuilt sideloadable binaries are made available for convenience, but redistribution is not permitted.

## Notes

* Some text and preview content may have been enhanced using AI tools.
* Code is primarily written manually, with occasional help from Xcode’s built-in AI suggestions.
* Codex has been used to generate some code. All AI-generated output was carefully reviewed, tested, and iterated on before being committed.
* ShelfPlayer is not affiliated with Apple, Audiobookshelf, or any third-party platform or service.

## Legal

[Terms of Service](https://github.com/rasmuslos/ShelfPlayer/blob/main/ToS.md) | [Privacy Policy](https://github.com/rasmuslos/ShelfPlayer/blob/main/Privacy.md) | [License](https://github.com/rasmuslos/ShelfPlayer/blob/main/LICENSE)
