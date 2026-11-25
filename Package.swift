// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Tazkira",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "TazkiraCore"),
        .executableTarget(name: "Tazkira", dependencies: ["TazkiraCore"]),
        .testTarget(name: "TazkiraCoreTests", dependencies: ["TazkiraCore"]),
    ]
)
