// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SentencePieceKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "SentencePieceKit",
            targets: ["SentencePieceKit"]),
    ],
    targets: [
        .binaryTarget(
            name: "sentencepiece",
            path: "./sentencepiece.xcframework"
        ),
        .target(
            name: "SentencePieceBridge",
            dependencies: ["sentencepiece"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "SentencePieceKit",
            dependencies: ["SentencePieceBridge"]
        ),
        .testTarget(
            name: "SentencePieceKitTests",
            dependencies: ["SentencePieceKit"]),
    ]
)
