// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "TMSyntax",
    products: [
        .library(name: "TMSyntax", targets: ["TMSyntax"]),
    ],
    dependencies: [
        .package(url: "https://github.com/omochi/FineJSON", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "TMSyntax", dependencies: ["FineJSON"]),
        .testTarget(name: "TMSyntaxTests", dependencies: ["TMSyntax"]),
    ]
)
