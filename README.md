# SentencePieceKit

A Swift package wrapper for Google's [SentencePiece](https://github.com/google/sentencepiece), allowing you to use SentencePiece tokenizer directly in your **iOS**, **macOS**, and **watchOS** projects.

This project includes a build script that automatically compiles the C++ C++ source code into a universal `xcframework` that supports:
- **iOS**: Device (arm64) & Simulator (arm64, x86_64)
- **macOS**: Apple Silicon (arm64) & Intel (x86_64)
- **watchOS**: Device (arm64_32, armv7k) & Simulator (arm64, x86_64)

---

## 📂 Project Structure

To use the build script, your directory structure **must** look like this:

```text
Projects/                  # Verification Root
├── sentencepiece/         # Cloned Google SentencePiece repository
└── SentencePieceKit/      # This project
    ├── Scripts/
    │   └── build_xcframework.sh
    └── Package.swift
```

> **Note**: The script assumes `sentencepiece` and `SentencePieceKit` are sibling directories.

## 🛠 Prerequisites

Ensure you have the following tools installed on your Mac:

- **Xcode** (with Command Line Tools)
- **CMake** (`brew install cmake`)
- **wget** (`brew install wget`) - *Used to download the iOS toolchain*

## 🚀 How to Build

1. **Clone Repositories**:
   ```bash
   # Go to your working directory
   cd Projects

   # 1. Clone Google's SentencePiece
   git clone https://github.com/google/sentencepiece.git

   # 2. Clone SentencePieceKit (if you haven't already)
   git clone https://github.com/your-repo/SentencePieceKit.git
   ```

2. **Run the Build Script**:
   ```bash
   cd SentencePieceKit/Scripts
   chmod +x build_xcframework.sh
   ./build_xcframework.sh
   ```

3. **Wait for Completion**:
   The script will:
   - Clean up previous builds.
   - Automatically download the necessary `ios.toolchain.cmake`.
   - Patch `CMakeLists.txt` for watchOS compatibility.
   - Compile for all platforms and architectures.
   - Generate `sentencepiece.xcframework`.

4. **Verify**:
   After the build finishes, you will see `sentencepiece.xcframework` in the root of `SentencePieceKit`.
   You can run the verification script to ensure all architectures are present:
   ```bash
   ./verify_kit.sh
   ```

## 📦 Installation in Xcode

1. Open your project in Xcode.
2. Go to **File > Add Package Dependencies...**
3. Add local `SentencePieceKit` package or drag `sentencepiece.xcframework` manually if you prefer direct linking.
4. Add `import SentencePieceKit` in your Swift code.

## 📝 License

- **SentencePiece**: Apache License 2.0 (Google)
- **SentencePieceKit**: [Apache License 2.0](LICENSE)
