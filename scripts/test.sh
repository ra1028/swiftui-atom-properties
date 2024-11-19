#!/bin/bash

set -eu

TARGET=$1
PLATFORM=$2
ARGS=${@:3}

pushd "$(cd $(dirname $0)/.. && pwd)" &>/dev/null

case $PLATFORM in
ios)
    platform="iOS Simulator,name=iPhone 15 Pro"
    ;;
macos)
    platform="macOS"
    ;;
tvos)
    platform="tvOS Simulator,name=Apple TV 4K (3rd generation)"
    ;;
watchos)
    platform="watchOS Simulator,name=Apple Watch Ultra 2 (49mm)"
    ;;
esac

clean_test() {
    xcodebuild clean test "$@" $ARGS
}

case $TARGET in
library)
    clean_test -scheme swiftui-atom-properties -destination platform="$platform"
    ;;
example-ios)
    cd Examples/Packages/iOS
    clean_test -scheme iOSExamples -destination platform="$platform"
    ;;
example-cross-platform)
    cd Examples/Packages/CrossPlatform
    clean_test -scheme CrossPlatformExamples -destination platform="$platform"
    ;;
benchmark)
    cd Benchmarks
    clean_test -scheme BenchmarkTests -destination platform="$platform"
    ;;
esac
