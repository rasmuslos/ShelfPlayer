// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShelfPlayerKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "SPBaseKit", targets: ["SPBaseKit", "SPOfflineKit", "SPExtensionKit"]),
        .library(name: "SPOfflineExtendedKit", targets: ["SPOfflineExtendedKit"]),
        .library(name: "SPPlaybackKit", targets: ["SPPlaybackKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "SPBaseKit",
            dependencies: [.byName(name: "SwiftSoup")],
            resources: [.process("Resources")],
            swiftSettings: [.define("_DISABLE_APP_GROUP")]),
        .target(name: "SPExtensionKit", dependencies: [.byName(name: "SPBaseKit"), .byName(name: "SPOfflineKit")]),
        .target(name: "SPPlaybackKit", dependencies: [.byName(name: "SPBaseKit"), .byName(name: "SPOfflineKit"), .byName(name: "SPOfflineExtendedKit", condition: .when(platforms: [.iOS]))]),
        
            .target(name: "SPOfflineKit", dependencies: [.byName(name: "SPBaseKit")], swiftSettings: [.define("_DISABLE_APP_GROUP")]),
        .target(name: "SPOfflineExtendedKit", dependencies: [.byName(name: "SPBaseKit"), .byName(name: "SPOfflineKit")]),
    ]
)
