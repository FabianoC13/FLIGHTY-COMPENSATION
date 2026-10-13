// swift-tools-version:5.9
// Runs the app's EU261/UK261 rules outside Xcode (macOS or Linux): `swift test`.
// Sources are symlinks to the files compiled into the app target, so there is one copy of the logic.
import PackageDescription

let package = Package(
    name: "EU261Core",
    targets: [
        .target(name: "EU261Core", path: "Sources/EU261Core"),
        .testTarget(name: "EU261CoreTests", dependencies: ["EU261Core"], path: "Tests/EU261CoreTests")
    ]
)
