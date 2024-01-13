// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShelfPlayerKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "ShelfPlayerKit", targets: ["ShelfPlayerKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .target(name: "ShelfPlayerKit", dependencies: [.byName(name: "SwiftSoup")], resources: [.process("Resources")], swiftSettings: [.define("_DISABLE_APP_GROUP")])
    ]
)
