#  ShelfPlayer

ShelfPlayer is a beautifully designed audio player for Audiobookshelf that feels right at home on iOS 17.

## Download

Available on the App Store soon™️

## Features

- Beautiful design
- Explore your Audiobooks, Podcasts, Episodes, Authors & Series
- Download audiobooks & episodes and listen to them on the go
- Sleep timer (custom time or until end of chapter)
- Siri integration
- Custom playback speed
- Automatic downloads & notifications

## Roadmap

### Short term

- Fix upcoming bugs
- https://nextcloud.rfk.io/s/iaaAKsad8SxQLfa

### Long term

- tvOS application
- Siri intents (episodes)

## Screenshots

| Library | Audiobook | Player | Podcast |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/PodcastLibrary.png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Audiobook.png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Podcast.png?raw=true" alt="Queue" width="200"/> 

## Sideload

**Pre built binaries**

Grab the [latest Release](https://github.com/rasmuslos/ShelfPlayer/releases/tag/v2.1.4) and install it using your favorite tool like SideStore.

Please not that the pre build binaries lack Siri and Widget support because these features either require a paid developer account or cannot be reliably implemented in a way that works with tools like SideStore. For further information see https://github.com/rasmuslos/ShelfPlayer/issues/20 & https://github.com/rasmuslos/ShelfPlayer/issues/4

This means that stripping app extensions is highly recommended, as they will not work as intended.

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
ShelfPlayer is not endorsed nor associated with Audiobookshelf
