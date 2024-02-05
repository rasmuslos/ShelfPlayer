#  ShelfPlayer

ShelfPlayer is a beautifully designed Audiobookshelf client that feels right at home on iOS 17.

## Download

Available on the App Store soon™️ \
\
Update: The app has been stuck in app review for nearly a month now. This is the second time i submitted it, the first time was on December the fifth. \
Also we are on version 2.1.2 now (as of Jan. 23) and build 91. The amount of commits nearly doubled since the app has been send to apple for review

<img src="/Screenshots/Review.png?raw=true" alt="Review" />

## Features

- Explore your Audiobooks, Podcasts, Authors & Series
- Download audiobooks & episodes and listen to them on the go
- Explore your authors, series, audiobooks, podcasts and episodes
- Fall asleep comfortably using the sleep timer
- Customize the playback speed

## Roadmap

### Short term
https://www.icloud.com/notes/0cdF-SSfHt3dSDX3zxtMsnuLg#Todo

### Long term
- Fix upcoming bugs
- Siri intents (episodes, audiobooks are already implemented)

## Screenshots

| Library | Audiobook | Player | Podcast |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/PodcastLibrary.png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Audiobook.png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Podcast.png?raw=true" alt="Queue" width="200"/> 

## Sideload

**Pre built binaries**

Grab the (latest Release)[https://github.com/rasmuslos/ShelfPlayer/releases/tag/v2.1.4] and install it using your favorite tool like SideStore.

Please not that the pre build binaries lack Siri and Widget support because these features either require a paid developer account or cannot be reliably implemented in a way that works with tools like SideStore. For further information see https://github.com/rasmuslos/ShelfPlayer/issues/20 & https://github.com/rasmuslos/ShelfPlayer/issues/4

This means that stripping app extensions is highly recommended, as they will not work as intended.

**Build the app yourself**

1. Install Xcode
2. Edit the configuration file called 'Base.xcconfig' in the `Configuration` directory
3. If you do not have a paid developer account remove the `ENABLE_ALL_FEATURES` compilation option, delete Siri option, and remove the group otherwise the app will crash
4. Connect your iPhone to your Mac
5. Enable developer mode
6. Select your iPhone as the run destination
7. Run the application

**Create an ipa**
you can also create an .ipa from Xcode, make sure to follow steps 1 and 2 from Build the App section
1. Go to Product -> Archive.
2. Once the App archives a new window opens right click on the archive and show in finder, open the archive with show package contents.
3. Go to Products-> Applications -> copy ShelfPlayer.app into a folder called Payload.
4. Compress Payload folder into a .zip
5. rename the .zip to ShelfPlayer.ipa, this will allow you to sideload the app as an ipa

## Licensing & Contributing

ShelfPlayer is licensed under the Mozilla Public License Version 2. Additionally the "Common Clause" applies. This means that you can modify ShelfPlayer, as well as contribute to it, but you are not allowed to distribute the application in binary form. Compiling for your own personal use is not covered by the commons clause and therefore fine. Additionally, prebuilt binaries are available on GitHub for side loading using popular tools like SideStore, etc.

Contributions are welcome, just fork the repository, and open a pull request with your changes. If you want to contribute translations you have to edit `Localizable.xcstrings` in the `iOS` directory, as well as `Localizable.xcstrings` located at `ShelfPlayerKit/Sources/SPBase/Resources` using Xcode. If you want to add a new language add it in the project settings

## Miscencainious

Please note that collections are not supported right now.
ShelfPlayer is not endorsed nor associated with Audiobookshelf
