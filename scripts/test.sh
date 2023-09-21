#!/bin/bash

set -eu

TARGET=$1
PLATFORM=$2

pushd "$(cd $(dirname $0)/.. && pwd)" &>/dev/null

case $PLATFORM in
ios)
    platform="iOS Simulator,name=iPhone 14 Pro"
    ;;
macos)
    platform="macOS"
    ;;
tvos)
    platform="tvOS Simulator,name=Apple TV 4K (3rd generation)"
    ;;
watchos)
    platform="watchOS Simulator,name=Apple Watch Ultra (49mm)"
    ;;
esac

case $TARGET in
product)
    xcodebuild test -scheme swiftui-atom-properties -destination platform="$platform"
    ;;
example-ios)
    cd Examples/Packages/iOS
    xcodebuild test -scheme iOSExamples -destination platform="$platform"
    ;;
example-cross-platform)
    cd Examples/Packages/CrossPlatform
    xcodebuild test -scheme CrossPlatformExamples -destination platform="$platform"
    ;;
esac
