# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SentencePieceKit is a Swift wrapper around Google's SentencePiece C++ tokenizer library, distributed as a Swift Package. It supports iOS 13+, macOS 11+, and watchOS 4+.

## Architecture

Three-layer bridge pattern:

1. **sentencepiece.xcframework** — Pre-compiled C++ static library (binary target)
2. **SentencePieceBridge** — Objective-C++ wrapper (`Sources/SentencePieceBridge/`) that converts between C++ and Objective-C types
3. **SentencePieceKit** — Swift public API (`Sources/SentencePieceKit/SentencePieceKit.swift`) exposing `SentencepieceTokenizer`

Dependency chain: `SentencePieceKit → SentencePieceBridge → sentencepiece (xcframework)`

The bridge layer (`SentencePieceBridge.mm`) is the only file that touches C++ directly. All Swift code interacts through the Objective-C interface defined in `SentencePieceBridge.h`.

## Build & Test Commands

```bash
swift build          # Build the package (macOS)
swift test           # Run tests (Swift Testing framework)
```

### Rebuilding the xcframework from source

Requires: cmake, lipo, xcodebuild, wget

```bash
bash Scripts/build_xcframework.sh   # Compiles C++ for all platforms
bash Scripts/verify_kit.sh          # Validates architectures and builds
```

## Key Files

- `Package.swift` — SPM config: swift-tools-version 5.9, 4 targets
- `Sources/SentencePieceKit/SentencePieceKit.swift` — Entire public API (~100 lines)
- `Sources/SentencePieceBridge/SentencePieceBridge.mm` — C++ interop (~70 lines)
- `Sources/SentencePieceBridge/include/SentencePieceBridge.h` — Bridge interface
- `Scripts/build_xcframework.sh` — Builds xcframework from SentencePiece C++ source
- `Example/` — iOS demo app (separate Xcode workspace, has its own CLAUDE.md)

## Conventions

- The class is named `SentencepieceTokenizer` (lowercase 'p') — preserve this casing
- The tokenizer is `@unchecked Sendable` because the underlying C++ processor is immutable and thread-safe after initialization
- Token offset support exists for compatibility with other tokenizer ecosystems (e.g., Hugging Face)
- Tests use the **Swift Testing** framework (`@Test`, `#expect`), not XCTest
- License: Apache 2.0
