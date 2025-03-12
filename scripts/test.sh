#!/bin/bash

set -eu

pushd "$(cd $(dirname $0)/.. && pwd)" &>/dev/null

target=$1
options=()
args=()

case $target in
library)
    options+=("-scheme swiftui-atom-properties")
    ;;
example-ios)
    cd Examples/Packages/iOS
    options+=("-scheme iOSExamples")
    ;;
example-cross-platform)
    cd Examples/Packages/CrossPlatform
    options+=("-scheme CrossPlatformExamples")
    ;;
benchmark)
    cd Benchmarks
    options+=("-scheme BenchmarkTests")
    ;;
esac

shift

while [[ $# -gt 0 ]]; do
    case "$1" in
    -destinations)
        shift
        while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
            options+=("-destination \"$1\"")
            shift
        done
        ;;
    *)
        args+=("$1")
        shift
        ;;
    esac
done

eval xcodebuild clean test "${options[@]-}" "${args[@]-}"
