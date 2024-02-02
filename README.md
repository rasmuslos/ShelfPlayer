#  ShelfPlayer

ShelfPlayer is a beautifully designed Audiobookshelf client that feels right at home on iOS 17.

## Download

Available on the App Store soon™️ \
\
Update: The app has been stuck in app review for nearly a month now. This is the second time i submitted it, the first time was on December the fifth. \
Also we are on version 2.1.2 now (as of Jan. 23) and build 91. The amount of commits nearly doubled since the app has been send to apple for review

<img src="/Screenshots/Review.png?raw=true" alt="Library" />

### Building the app yourself

**Install using your favorite Side loading tool**

Download and install the latest release \
*Please strip app extensions (widgets, siri support, ...), they will not work as intented see https://github.com/rasmuslos/ShelfPlayer/issues/4*

**Build the app yourself**

1. Install Xcode
2. Change the bundle identifier
3. Connect your iPhone to your Mac
4. Enable developer mode
5. Select your iPhone as the target
6. Run the application

## Features

- Explore your Audiobooks, Podcasts, Authors & Series
- Download audiobooks & episodes and listen to them on the go
- Explore your authors, series, audiobooks, podcasts and episodes
- Fall asleep comfortably using the sleep timer
- Customize the playback speed

## Roadmap

- Fix upcoming bugs
- tvOS application
- Siri intents

## Screenshots

| Library | Audiobook | Player | Podcast |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/PodcastLibrary.png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Audiobook.png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Podcast.png?raw=true" alt="Queue" width="200"/> 

Please note that collections are not supported right now.
ShelfPlayer is not endorsed nor associated with Audiobookshelf

# Licensing & Contributing

ShelfPlayer is licensed under the Mozilla Public License Version 2. Additionally the "Common Clause" applies. This means that you can modify ShelfPlayer, as well as contribute to it, but you are not allowed to distribute the application in binary form. Compiling for your own personal use is not covered by the commons clause and therefore fine. Additionally, prebuilt binaries are available on GitHub for side loading using popular tools like SideStore, etc.

Contributions are welcome, just fork the repository, and open a pull request with your changes. If you want to contribute translations you have to edit `Localizable.xcstrings` in the `iOS` directory, as well as `Localizable.xcstrings` located at `ShelfPlayerKit/Sources/SPBase/Resources` using Xcode. If you want to add a new language add it in the project settings
