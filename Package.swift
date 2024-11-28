// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StitchViewKit",
    platforms: [
        .macOS(.v14), .iOS(.v17), .macCatalyst(.v17)
    ],
    products: [
        .library(name: "StitchViewKit",
                 targets: ["StitchViewKit"])
    ],
    targets: [
        .target(name: "StitchViewKit")
    ]
)
