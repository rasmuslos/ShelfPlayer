// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShelfPlayerKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "SPBase", targets: ["SPBase", "SPOffline"]),
        .library(name: "SPOfflineExtended", targets: ["SPOfflineExtended"]),
        .library(name: "SPPlayback", targets: ["SPPlayback"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/sindresorhus/Defaults", from: .init(8, 0, 0))
    ],
    targets: [
        .target(
            name: "SPBase",
            dependencies: [.byName(name: "SwiftSoup")],
            resources: [.process("Resources")],
            swiftSettings: [.define("_DISABLE_APP_GROUP")]),
        .target(name: "SPPlayback", dependencies: [
            .byName(name: "Defaults"),
            
            .byName(name: "SPBase"),
            .byName(name: "SPOffline"),
            .byName(name: "SPOfflineExtended", condition: .when(platforms: [.iOS]))
        ]),
        
        .target(name: "SPOffline", dependencies: [.byName(name: "SPBase")], swiftSettings: [.define("_DISABLE_APP_GROUP")]),
        .target(name: "SPOfflineExtended", dependencies: [.byName(name: "SPBase"), .byName(name: "SPOffline")]),
    ]
)
