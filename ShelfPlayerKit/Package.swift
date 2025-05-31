// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShelfPlayerKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        .library(name: "ShelfPlayerKit", targets: ["ShelfPlayerKit"]),
        .library(name: "SPPlayback", targets: ["SPPlayback"]),
    ],
    dependencies: [
        .package(url: "https://git.sr.ht/~rasmuslos/RFKit", branch: "main"),
        
        .package(url: "https://github.com/kean/Nuke", from: .init(12, 1, 6)),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: .init(2, 6, 0)),
        .package(url: "https://github.com/sindresorhus/Defaults", from: .init(9, 0, 0)),
    ],
    targets: [
        // Umbrella library
        .target(name: "ShelfPlayerKit", dependencies: [
            .targetItem(name: "SPFoundation", condition: .none),
            .targetItem(name: "SPNetwork", condition: .none),
            .targetItem(name: "SPPersistence", condition: .none),
            
            .byName(name: "RFKit"),
        ]),
        
        // Foundation
        .target(
            name: "SPFoundation",
            dependencies: [
                .byName(name: "RFKit"),
                .byName(name: "SwiftSoup"),
                
                .product(name: "Defaults", package: "Defaults"),
            ]
        ),
        
        // Network
        .target(name: "SPNetwork", dependencies: [
            .byName(name: "RFKit"),
            .byName(name: "Nuke"),
            
            .targetItem(name: "SPFoundation", condition: .none),
        ]),
        
        // Persistence
        .target(name: "SPPersistence", dependencies: [
            .byName(name: "RFKit"),
            .product(name: "Defaults", package: "Defaults"),
            
            .targetItem(name: "SPFoundation", condition: .none),
            .targetItem(name: "SPNetwork", condition: .none),
        ]),
        
        // Playback
        .target(name: "SPPlayback", dependencies: [
            .byName(name: "RFKit"),
            
            .product(name: "Defaults", package: "Defaults"),
            .product(name: "DefaultsMacros", package: "Defaults"),
            
            .targetItem(name: "SPFoundation", condition: .none),
            .targetItem(name: "SPPersistence", condition: .none),
        ]),
    ]
)
