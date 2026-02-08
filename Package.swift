// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlowTimer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FlowTimer",
            targets: ["FlowTimer"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FlowTimer",
            dependencies: [],
            path: ".",
            exclude: [
                "Resources/Assets.xcassets",
                "FlowTimer.entitlements",
                "Package.swift",
                "Tests"
            ],
            sources: [
                "FlowTimerApp.swift",
                "AppDelegate.swift",
                // Views
                "Views/ContentView.swift",
                "Views/SettingsView.swift",
                // FlipClock Views
                "Views/FlipClock/DigitHalfView.swift",
                "Views/FlipClock/FlipDigitView.swift",
                "Views/FlipClock/FlipClockView.swift",
                // Control Views
                "Views/Controls/ControlButtonsView.swift",
                "Views/Controls/DurationPickerView.swift",
                "Views/Controls/SoundPickerView.swift",
                // History Views
                "Views/History/SessionListView.swift",
                "Views/History/StatsSummaryView.swift",
                "Views/History/HistoryView.swift",
                // Menu Bar
                "Views/MenuBar/MenuBarController.swift",
                // Models
                "Models/TimerState.swift",
                "Models/AmbientSound.swift",
                "Models/FlowSession.swift",
                "Models/TimePeriod.swift",
                // Managers
                "Managers/TimerManager.swift",
                "Managers/AudioManager.swift",
                "Managers/FocusManager.swift",
                "Managers/SessionStore.swift",
                "Managers/PreferencesManager.swift"
            ],
            resources: [
                .process("Resources/Sounds")
            ]
        ),
        .testTarget(
            name: "FlowTimerTests",
            dependencies: ["FlowTimer"],
            path: "Tests"
        )
    ]
)
