#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
xcrun swiftc -module-cache-path build/ModuleCache Sources/GestureRecognizer.swift Tests/main.swift -o build/RecognizerTests
build/RecognizerTests
