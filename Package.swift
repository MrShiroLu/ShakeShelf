// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShakeShelf",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "ShakeCore"),
        .executableTarget(name: "ShakeShelf", dependencies: ["ShakeCore"]),
        // Plain executable because XCTest and Swift Testing need a full Xcode install.
        .executableTarget(name: "ShakeChecks", dependencies: ["ShakeCore"]),
    ]
)
