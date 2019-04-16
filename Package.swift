// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "collapser",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "1.7.4"),
        .package(url: "https://github.com/IBM-Swift/swift-html-entities.git", from: "3.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "collapser",
            dependencies: ["SwiftSoup", "HTMLEntities"]
            ),
        .testTarget(
            name: "collapserTests",
            dependencies: ["SwiftSoup", "collapser", "HTMLEntities"]),
    ]
)
