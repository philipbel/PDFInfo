#!/bin/bash


libs=(pdf-engine font-locator)

ARCH="$(uname -m)"

case "$(uname -s)" in
    Darwin)
        SYSTEM=macos
        ;;
    *)
        echo "Not implemented";
        exit 1
        ;;
esac


for d in "${libs[@]}"; do 
    cmake \
        -S "${d}/core" \
        -B "build/macos/universal/${d}-core" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
        -DCMAKE_PREFIX_PATH="${PWD}/build/prefix/${SYSTEM}/${ARCH}" \
        -DDEPS_UNIVERSAL_LIB_DIR="${PWD}/build/prefix/${SYSTEM}/universal/lib" \
        || exit 1

    cmake \
        --build "build/macos/universal/${d}-core" || exit 1

    cmake \
        --install "build/macos/universal/${d}-core" \
        --prefix "${PWD}/build/prefix/macos/universal" || exit 1
done
