// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShelfPlayerKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "ShelfPlayerKit", targets: ["ShelfPlayerKit"]),
        .library(name: "SPPlayback", targets: ["SPPlayback"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke", from: .init(12, 1, 6)),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: .init(2, 6, 0)),
        .package(url: "https://github.com/sindresorhus/Defaults", from: .init(8, 2, 0)),
    ],
    targets: [
        // Umbrella library
        .target(name: "ShelfPlayerKit", dependencies: [
            .targetItem(name: "SPFoundation", condition: .none),
            .targetItem(name: "SPExtension", condition: .none),
            .targetItem(name: "SPNetwork", condition: .none),
            .targetItem(name: "SPPersistence", condition: .none),
        ]),
        
        // Foundation
        .target(
            name: "SPFoundation",
            dependencies: [
                .byName(name: "Defaults"),
                .byName(name: "SwiftSoup"),
            ]
        ),
        .target(name: "SPExtension", dependencies: [
            .targetItem(name: "SPFoundation", condition: .none),
            .targetItem(name: "SPPersistence", condition: .none),
        ]),
        
        // Network
        .target(name: "SPNetwork", dependencies: [
            .targetItem(name: "SPFoundation", condition: .none),
            
            .byName(name: "Nuke"),
        ]),
        
        // Offline
        .target(name: "SPPersistence", dependencies: [
            .byName(name: "Defaults"),
            
            .targetItem(name: "SPFoundation", condition: .none),
            .targetItem(name: "SPNetwork", condition: .none),
        ]),
        
        // Playback
        .target(name: "SPPlayback", dependencies: [
            .byName(name: "Defaults"),
            
            .targetItem(name: "SPFoundation", condition: .none),
            .targetItem(name: "SPExtension", condition: .none),
            .targetItem(name: "SPPersistence", condition: .none),
        ]),
    ]
)
