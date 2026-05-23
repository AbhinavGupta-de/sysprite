// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sysprite",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Sysprite",
            path: "Sources/Sysprite"
        ),
        .testTarget(
            name: "SyspriteTests",
            dependencies: ["Sysprite"],
            path: "Tests/SyspriteTests"
        )
    ]
)
