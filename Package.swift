// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Todos",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "Todos",
            path: "Sources/Todos"
        )
    ]
)
