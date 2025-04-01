#  ShelfPlayer

ShelfPlayer is a meticulously crafted iOS and iPadOS app designed to seamlessly integrate with your Audiobookshelf library. Enjoy a captivating listening experience with its sleek interface, lightning-fast performance, and deep system integration.

## Features:

- **Immersive Exploration**: Effortlessly navigate through your audiobooks, podcasts, episodes, authors, and series with our beautifully designed interface.
- **Synchronized Listening**: Accurately track your listening progress and seamlessly sync your statistics with Audiobookshelf.
- **Offline Enjoyment**: Download your favorite audiobooks and episodes to indulge in uninterrupted listening, even without an internet connection.
- **Personalized Sleep**: Wind down with our customizable sleep timer, which automatically pauses playback at your desired time, even at the end of a chapter.
- **Voice Control**: Enjoy hands-free convenience with Siri integration and create custom shortcuts for effortless playback.
- **Tailored Listening**: Adjust playback speed to match your preferred listening pace.
- **Automated Convenience**: Automatically download new episodes and receive notifications to stay up-to-date with your favorite shows.

## Download

<a href="https://apps.apple.com/app/apple-store/id6475221163?ct=GitHub" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;">
    <img src="https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us?releaseDate=1710288000" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;">
</a>

## Screenshots

| Home | Audiobook | Player | Podcast |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/iOS%20Audiobook%20Home.png?raw=true" alt="Home (iOS)" width="200"/> | <img src="/Screenshots/iOS%20Audiobook.png?raw=true" alt="audiobook" width="200"/> | <img src="/Screenshots/iOS%20Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/iOS%20Podcast.png?raw=true" alt="width" width="200"/> 
| <img src="/Screenshots/iPadOS%20Audiobook%20Home.png?raw=true" alt="Home (iPad)" width="200"/> | <img src="/Screenshots/iPadOS%20Audiobook.png?raw=true" alt="Audiobook" width="200"/> | <img src="/Screenshots/iPadOS%20Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/iPadOS%20Podcast.png?raw=true" alt="Podcast" width="200"/> 

## Sideload

### Pre-built

Grab the [latest Release](https://github.com/rasmuslos/ShelfPlayer/releases/latest) and install it using your favorite tool like SideStore.

> [!WARNING]
> Pre-built versions of ShelfPlayer lack Siri support due to limitations with sideloading tools. These features require a paid developer account or can't be reliably implemented for sideloaded apps. See https://github.com/rasmuslos/ShelfPlayer/issues/20 & https://github.com/rasmuslos/ShelfPlayer/issues/4 for more information.

Stripping app extensions is highly recommended as they won't function correctly when sideloaded. 

### Build ShelfPlayer Yourself

If you're comfortable with Xcode, you can build ShelfPlayer yourself:

1. Install Xcode on your Mac.
2. In the `Configuration` directory, copy the `Debug.xcconfig.template` file and rename it to `Debug.xcconfig`.
3. Edit `Debug.xcconfig`:
    * Change `DEVELOPMENT_TEAM` to your Apple developer team ID.
    * Set a unique `BUNDLE_ID_PREFIX` (e.g., me.yourname).
    * If you don't have a paid developer account, remove the `ENABLE_ALL_FEATURES` compilation condition to avoid crashes.
    * You can also remove the `DEBUG` flag if you don't intend on further development.
    * If you have access to the [CarPlay entitlement](https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements) comment out the last line, otherwise proceed.
4. Connect your iPhone to your Mac and enable developer mode.
5. Select your iPhone as the run destination in Xcode.
6. Run the application.

> [!NOTE]
> The `DEBUG` configuration is used by default for most builds. To create a release build for distribution (which isn't allowed under the license), you'll need to edit the `Release.xcconfig` file.

## Licensing & Contributing

> [!WARNING]
> ShelfPlayer is undergoing a massive backend rewrite at the moment. See #189. If you want to contribute please wait until it is finished or make a pull request against the [`inents`](https://github.com/rasmuslos/ShelfPlayer/tree/inents) branch.

ShelfPlayer is licensed under the Mozilla Public License Version 2. Additionally the "Common Clause" applies. This means that you can modify ShelfPlayer, as well as contribute to it, but you are not allowed to distribute the application in binary form. Compiling for your own personal use is not covered by the commons clause and therefore fine. Additionally, prebuilt binaries are available on GitHub for side loading using popular tools like SideStore, etc.

Contributions are welcome, just fork the repository, and open a pull request with your changes. If you want to contribute translations you have to edit `Localizable.xcstrings` in the `iOS` directory, as well as one line in `InfoPlist.xcstrings` located at the same directory using Xcode. If you want to add a new language add it in the project settings (The root of the Xcode project named "ShelfPlayer").

## Miscellaneous

- ShelfPlayer is not endorsed by nor associated with Audiobookshelf
- I generated some parts of this readme using Gemini, too
