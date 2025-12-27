// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SentencePieceKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SentencePieceKit",
            targets: ["SentencePieceKit"]),
    ],
    targets: [
        // 1. C++ 바이너리 타겟 (XCFramework 연결)
        .binaryTarget(
            name: "sentencepiece",
            path: "./sentencepiece.xcframework"
        ),
        // 2. Swift 래퍼 타겟
        .target(
            name: "SentencePieceKit",
            dependencies: ["sentencepiece"],
            swiftSettings: [
                .interoperabilityMode(.Cxx) // C++ 연동 활성화
            ]
        ),
        .testTarget(
            name: "SentencePieceKitTests",
            dependencies: ["SentencePieceKit"]),
    ]
)
