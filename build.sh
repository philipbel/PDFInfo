#!/usr/bin/env bash

set -eu -o pipefail

ROOT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
STEP=${1:-}
CMAKE="${CMAKE:-cmake}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
CMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES:-arm64;x86_64}"
CMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET:-14.0}"

BUILD_TYPE_STR=$(echo "${BUILD_TYPE}" | tr '[:upper:]' '[:lower:]')

BUILD_DIR="${BUILD_DIR:-${ROOT_DIR}/build/${BUILD_TYPE_STR}}"
PREFIX_DIR="${PREFIX_DIR:-${ROOT_DIR}/build/${BUILD_TYPE_STR}}"


# 1 - name
# 2 - relative path
function configure_lib() {
    echo "Configuring ${1}"
    "${CMAKE}" \
        -S "${ROOT_DIR}/${2}" \
        -B "${BUILD_DIR}/${1}" \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
        -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
        -DCMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES}" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}"
}

function do_configure() {
    configure_lib pdf-engine-core pdf-engine/core
    configure_lib font-locator-core font-locator/core
}


# 1 - name
function build_lib() {
    echo "Building ${1}"
    "${CMAKE}" \
        --build "${BUILD_DIR}/${1}"
}

function do_build() {
    build_lib pdf-engine-core
    build_lib font-locator-core
}


# 1 - name
function install_lib() {
    echo "Installing ${1}"
    "${CMAKE}" \
        --install "${BUILD_DIR}/${1}"
}

function do_install() {
    install_lib pdf-engine-core
    install_lib font-locator-core
}


if [ -z "${STEP}" ]; then 
    do_configure
    do_build
    do_install
elif [ "${STEP}" = "configure" ]; then
    do_configure
elif [ "${STEP}" = "build" ]; then
    do_build
elif [ "${STEP}" = "install" ]; then
    do_install
else
    echo "Unrecognized parameter ${STEP}"
    exit 1
fi
