// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShelfPlayerKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "SPBase", targets: ["SPBase", "SPExtension", "SPOffline"]),
        .library(name: "SPOfflineExtended", targets: ["SPOfflineExtended"]),
        .library(name: "SPPlayback", targets: ["SPPlayback"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: .init(2, 6, 0)),
        .package(url: "https://github.com/sindresorhus/Defaults", from: .init(8, 0, 0)),
        .package(url: "https://github.com/FelixHerrmann/UIImageColors.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "SPBase",
            dependencies: [
                .byName(name: "Defaults"),
                .byName(name: "SwiftSoup"),
                .byName(name: "UIImageColors"),
            ],
            resources: [.process("Resources")]),
    
        .target(name: "SPExtension", dependencies: [
            .byName(name: "SPBase"),
            .byName(name: "SPOffline"),
            .byName(name: "SPOfflineExtended", condition: .when(platforms: [.iOS, .watchOS, .visionOS, .macOS]))
        ]),
        
        .target(name: "SPOffline", dependencies: [
            .byName(name: "SPBase"),
            .byName(name: "Defaults"),
        ]),
        .target(name: "SPOfflineExtended", dependencies: [
            .byName(name: "SPBase"),
            .byName(name: "SPOffline"),
        ]),
        
        .target(name: "SPPlayback", dependencies: [
            .byName(name: "Defaults"),
            .byName(name: "SPBase"),
            
            .byName(name: "SPOffline"),
            .byName(name: "SPExtension"),
            .byName(name: "SPOfflineExtended", condition: .when(platforms: [.iOS, .watchOS, .visionOS, .macOS])),
        ]),
    ]
)
