// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CCMeter",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "CCMeter",
            path: "Sources/CCMeter"
        )
    ]
)
