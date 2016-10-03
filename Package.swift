import PackageDescription

let package = Package(
    name: "SwiftDiscord",
    targets: [
    	Target(name: "Runner", dependencies: ["SwiftDiscord"]),
    	Target(name: "SwiftDiscord")
    ],
    dependencies: [
    	.Package(url: "https://github.com/daltoniam/Starscream", majorVersion: 2),
    	.Package(url: "https://github.com/nuclearace/copus", majorVersion: 1)
    ]
)
