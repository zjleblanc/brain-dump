// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrainDump",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "BrainDump",
            path: "Sources/BrainDump",
            exclude: ["Resources/AppIcon.icns", "Resources/AppIcon.png"]
        )
    ]
)
