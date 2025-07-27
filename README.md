# ShelfPlayer

**ShelfPlayer** is a powerful iOS application for listening to audiobooks and podcasts, designed for users with self-hosted [Audiobookshelf](https://www.audiobookshelf.org/) libraries. Built in **Swift 6** for **iOS 18+**, ShelfPlayer is fast, privacy-respecting, and deeply integrated with the Apple ecosystem.

> [!WARNING]
> ShelfPlayer does not include any media content. A running Audiobookshelf instance is required to use the app.

## Features

* **Full content browsing**: Explore audiobooks, authors, narrators, series, podcasts, episodes, collections, and playlists.
* **Multiple users and libraries**: Connect to multiple Audiobookshelf servers or user accounts simultaneously.
* **System-level integration**: Supports Widgets, Siri, App Intents, and CarPlay.
* **Global discovery**: "Listen Now" and universal search work across all connected libraries.
* **Advanced playback tools**: Highly configurable playback speed and sleep timer.
* **Daily listen tracking**: Accurate tracking of playback time, with optional daily goals.
* **PDF viewer**: Built-in support for attached PDF documents.
* **Offline access**: Automatic media downloads for seamless offline playback.
* **Modern interface**: Clean, native design optimized for both iPhone and iPad.

## Download

<a href="https://apps.apple.com/app/apple-store/id6475221163?ct=GitHub" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;">
    <img src="https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us?releaseDate=1710288000" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;">
</a>

## Screenshots
| Audiobook                                                                                      | Podcast                                                                               | Player                                                                          | Other                                                                                             |
| ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| <img src="/Screenshots/iOS%20Audiobook.png?raw=true" alt="Audiobook (iOS)" width="200"/>       | <img src="/Screenshots/iOS%20Podcast.png?raw=true" alt="Podcast" width="200"/>        | <img src="/Screenshots/iOS%20Player.png?raw=true" alt="Player" width="200"/>    | <img src="/Screenshots/iOS%20Playlist.png?raw=true" alt="Playlist" width="200"/> 
| <img src="/Screenshots/iPadOS%20Audiobook.png?raw=true" alt="Audiobook (iPad)" width="200"/> | <img src="/Screenshots/iPadOS%20Podcast.png?raw=true" alt="Podcast" width="200"/> | <img src="/Screenshots/iPadOS%20Player.png?raw=true" alt="Player" width="200"/> | <img src="/Screenshots/iOS%20Listen%20Now.png?raw=true" alt="Listen Now" width="200"/> |

## Sideloading

### Prebuilt Releases

Download the latest release from the [Releases](https://github.com/yourusername/shelfplayer/releases) page and install it using tools such as SideStore.

**Important limitations when sideloading:**

* Siri is not supported without a paid Apple Developer account due to entitlement restrictions.
* App extensions (e.g., Widgets) may not function correctly; it is recommended to remove them before sideloading.
* For background and technical details, see [issue #20](https://github.com/yourusername/shelfplayer/issues/20) and [issue #4](https://github.com/yourusername/shelfplayer/issues/4).

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
* Code was written manually with occasional help from Xcode's built-in AI suggestions.
* ShelfPlayer is not affiliated with Apple, Audiobookshelf, or any third-party platform or service.
