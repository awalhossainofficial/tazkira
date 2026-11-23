// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Zikr",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ZikrCore"),
        .executableTarget(name: "Zikr", dependencies: ["ZikrCore"]),
        .testTarget(name: "ZikrCoreTests", dependencies: ["ZikrCore"]),
    ]
)
