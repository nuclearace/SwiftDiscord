// swift-tools-version:5.3

// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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

let package = Package(
    name: "swift-discord",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Discord", targets: ["Discord"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/websocket-kit.git", .upToNextMinor(from: "2.1.0")),
        .package(name: "Socket", url: "https://github.com/Kitura/BlueSocket.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1"),
    ],
    targets: [
        .target(name: "Discord", dependencies: [
            .product(name: "WebSocketKit", package: "websocket-kit"),
            .product(name: "Socket", package: "Socket"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "BigInt", package: "BigInt"),
        ]),
        .testTarget(name: "DiscordTests", dependencies: [
            .target(name: "Discord"),
        ]),
    ]
)
