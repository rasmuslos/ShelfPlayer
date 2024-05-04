#  ShelfPlayer

ShelfPlayer is a sleek and modern Audiobookshelf client, specifically designed for audiobooks, podcasts and iOS, as well as iPadOS. Due to its design, snappy interface and deep integration it feels right at home on any supported device.

## Features:

- Explore your Audiobooks, Podcasts, Episodes, Authors & Series: Use the beautiful UI to rediscover your favorite content
- Sync listening statistics: ShelfPlayer will accurately update your Audiobookshelf listening stats
- Download audiobooks & episodes and listen to them on the go: The app is designed to work as well offline as if you were at home
- Sleep timer: Set a sleep timer to automatically stop playback, even at the end of the current chapter
- Siri & Shortcuts integration: Use Siri to play your audiobooks or podcast episodes
- Custom playback speed: Customize the playback speed
- Automatic downloads & notifications: Download new episodes automatically in the background

## Download

<a href="https://apps.apple.com/app/shelfplayer/id6475221163?itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1710288000" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>

## Roadmap

Things to implement before i would consider ShelfPlayer feature complete:

- Shortcuts
- Bookmarks
- Lazy loading

### iOS

- CarPlay (online) integration
- Tweak now playing animation (port from AmpFin)
- Widgets (No idea what purpose they could serve but there may be some)

### Planned platforms

- iPadOS
- macOS

### Things that are not possible due to a lack of APIs provided by Apple:

- Journal integration
- Now playing widget suggestions
- Queue in the Apple Watch now playing app
- HomePod (possible but would require a centralized server)

## Screenshots

| Library | Audiobook | Player | Podcast |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/Library.png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Audiobook.png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Podcast.png?raw=true" alt="Queue" width="200"/> 
| <img src="/Screenshots/Library%20(iPad).png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Audiobook%20(iPad).png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player%20(iPad).png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Podcast%20(iPad).png?raw=true" alt="Queue" width="200"/> 

## Sideload

**Pre built binaries**

Grab the [latest Release](https://github.com/rasmuslos/ShelfPlayer/releases/latest) and install it using your favorite tool like SideStore.

Please not that the pre build binaries lack Siri and Widget support because these features either require a paid developer account or cannot be reliably implemented in a way that works with tools like SideStore. For further information see https://github.com/rasmuslos/ShelfPlayer/issues/20 & https://github.com/rasmuslos/ShelfPlayer/issues/4

Stripping app extensions is highly recommended, they will not work as intended.

**Build the app yourself**

1. Install Xcode
2. In the `Configuration` directory copy the `Debug.xcconfig.template` file and rename it to `Debug.xcconfig`
3. Change the `DEVELOPMENT_TEAM` to your apple developer team id and `BUNDLE_ID_PREFIX` to a prefix of your liking
4. If you do not have a paid developer account remove the `ENABLE_ALL_FEATURES` compilation condition. Otherwise the app will crash. If you do not intent on developing the app also remove the `DEBUG flag`
5. Connect your iPhone to your Mac & enable developer mode
6. Select your iPhone as the run destination
7. Run the application

Please not that the `DEBUG` configuration is used by default for all builds except archiving and profiling. You have to edit `Release.xcconfig` to update their parameters.

## Licensing & Contributing

ShelfPlayer is licensed under the Mozilla Public License Version 2. Additionally the "Common Clause" applies. This means that you can modify ShelfPlayer, as well as contribute to it, but you are not allowed to distribute the application in binary form. Compiling for your own personal use is not covered by the commons clause and therefore fine. Additionally, prebuilt binaries are available on GitHub for side loading using popular tools like SideStore, etc.

Contributions are welcome, just fork the repository, and open a pull request with your changes. If you want to contribute translations you have to edit `Localizable.xcstrings` in the `iOS` directory, as well as `Localizable.xcstrings` located at `ShelfPlayerKit/Sources/SPBase/Resources` using Xcode. If you want to add a new language add it in the project settings

## Miscellaneous

Please note that collections are not supported right now.
ShelfPlayer is not endorsed by nor associated with Audiobookshelf
