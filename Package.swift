// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StitchViewKit",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .library(name: "StitchViewKit",
                 targets: ["StitchViewKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/vpl-codesign/SwipeActions.git", branch: "main")
    ],
    targets: [
        .target(name: "StitchViewKit", dependencies: ["SwipeActions"])
    ]
)
