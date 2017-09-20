// swift-tools-version:4.0

// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import PackageDescription

var deps: [Package.Dependency] = [
    .package(url: "https://github.com/nuclearace/copus", .upToNextMajor(from: "2.0.0")),
    .package(url: "https://github.com/nuclearace/Sodium", .upToNextMajor(from: "2.0.0")),
    .package(url: "https://github.com/vapor/engine", .upToNextMajor(from: "2.2.0")),
]

var targetDeps: [Target.Dependency] = ["DiscordOpus", "WebSockets"]

#if !os(Linux)
deps += [.package(url: "https://github.com/nuclearace/Starscream", .upToNextMajor(from: "2.1.0")),] // TODO use 2.2.0 when it's available
targetDeps += ["Starscream"]
#endif


let package = Package(
    name: "SwiftDiscord",
    products: [
        .library(name: "SwiftDiscord", targets: ["SwiftDiscord"])
    ],
    dependencies: deps,
    targets: [
        .target(name: "SwiftDiscord", dependencies: targetDeps),
        .target(name: "DiscordOpus"),
        .testTarget(name: "SwiftDiscordTests", dependencies: ["SwiftDiscord"]),
    ]
)
