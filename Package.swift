// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macos-task-cleaner-gui",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TaskCleanerGUI", targets: ["TaskCleanerGUI"])
    ],
    targets: [
        .executableTarget(
            name: "TaskCleanerGUI",
            path: "Sources"
        )
    ]
)
