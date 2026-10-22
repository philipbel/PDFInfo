#!/usr/bin/env bash


set -eu -o pipefail

ROOT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd)
SELF="$(basename "$0")"
CMAKE="${CMAKE:-cmake}"

BUILD_TYPE="Release"
ARCHITECTURES=()
DEPLOYMENT_TARGET="14.0"
TARGETS=()
VERBOSE=0
STEPS=()
_ALL_BUILD_TYPES=(Debug Release)
_ALL_TARGETS=(pdf-engine-core font-locator-core)
_ALL_STEPS=(configure build install)

function usage() {
    cat << EOF
    Usage: $SELF [OPTIONS] [STEPS]

    STEPS is one or more of (${_ALL_STEPS[@]}). Default is empty = all steps.

    Options:
        -t TARGET     Specify target, one of (${_ALL_TARGETS[@]}) [empty].
                      Can be issued more than once.
        -B BUILD_DIR  Specify build directory [${ROOT_DIR}/build/<BUILD_TYPE>].
        -P PREFIX_DIR Specify prefix directory [${ROOT_DIR}/build/<BUILD_TYPE>].
        -a ARCH       Specify architecture to build [empty].
                      Can be issued more than once.
        -m OS-TARGET  Specify macOS deployment target [${DEPLOYMENT_TARGET}].
        -b BUILD_TYPE Build type, one of (${_ALL_BUILD_TYPES[@]}) [release].
        -d            Build in debug mode, same as \`-b Debug' [false].
        -r            Build in release mode, same as \`-b Release' [true].
        -v            Show verbose messages.
        -h            Show this message and exit.
EOF
}

# $1 - string
# $2... - strings
# Returns 0 if $1 is equal to any of the following parameters
function contains() {
    local value="${1}"
    shift
    local item
    for item in "${@}"; do
        if [ "${value}" = "${item}" ]; then
            return 0
        fi
    done
    return 1
}

while getopts "t:B:P:m:a:b:vhdr" opt; do
    case "${opt}" in
        t) 
            if contains "${OPTARG}" "${_ALL_TARGETS[@]}"; then
                TARGETS+=("${OPTARG}")
            else
                echo "$SELF: Unknown target '${OPTARG}'" > /dev/stderr
                usage > /dev/stderr
                exit 1
            fi
            ;;
        B) BUILD_DIR="${OPTARG}" ;;
        P) PREFIX_DIR="${OPTARG}" ;;
        a) ARCHITECTURES+=("${OPTARG}") ;;
        m) DEPLOYMENT_TARGET="${OPTARG}" ;;
        b)
            _first_char=$(echo "${OPTARG:0:1}" | tr '[:lower:]' '[:upper:]')
            _rest_chars=$(echo "${OPTARG:1}" | tr '[:upper:]' '[:lower:]')
            _build_type="${_first_char}${_rest_chars}"
            if contains "${_build_type}" "${_ALL_BUILD_TYPES[@]}"; then
                BUILD_TYPE="${_build_type}"
            else
                echo "$SELF: Invalid build type '${OPTARG}'" > /dev/stderr
                usage > /dev/stderr
                exit 1
            fi
            ;;
        d) BUILD_TYPE="Debug" ;;
        r) BUILD_TYPE="Release" ;;
        v) VERBOSE=1 ;;
        h) usage ; exit 0 ;;
        \?) usage > /dev/stderr; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
while [ $# -gt 0 ]; do
    STEPS+=("$1")
    shift
done

_build_type_lower=$(echo "${BUILD_TYPE}" | tr '[:upper:]' '[:lower:]')
PREFIX_DIR="${PREFIX_DIR:-${ROOT_DIR}/build/${_build_type_lower}}"
BUILD_DIR="${BUILD_DIR:-${PREFIX_DIR}}"

if [ "${#STEPS[@]}" -eq 0 ]; then
    STEPS=("${_ALL_STEPS[@]}")
else
    for s in "${STEPS[@]}"; do
        if ! contains "${s}" "${_ALL_STEPS[@]}"; then
            echo "$SELF: Invalid step '${s}'" > /dev/stderr
            usage > /dev/stderr
            exit 1
        fi
    done
fi
if [ "${#ARCHITECTURES[@]}" -eq 0 ]; then
    ARCHITECTURES=(arm64 x86_64)
fi
if [ "${#TARGETS[@]}" -eq 0 ]; then
    TARGETS=(pdf-engine-core font-locator-core)
fi


function begin_verbose() {
    if [ "${VERBOSE}" -eq 1 ]; then
        set -x
    fi
}

function end_verbose() {
    if [ "${VERBOSE}" -eq 1 ]; then
        set +x
    fi
}


# 1 - name
# 2 - relative path
function configure_lib() {
    echo "Configuring ${1}"
    local architectures

    architectures=$(IFS=';'; echo "${ARCHITECTURES[*]}")
    begin_verbose
    "${CMAKE}" \
        -S "${ROOT_DIR}/${2}" \
        -B "${BUILD_DIR}/${1}" \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
        -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
        -DCMAKE_OSX_ARCHITECTURES="${architectures}" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}"
    { end_verbose; } 2>/dev/null
}

# 1 - name
function build_lib() {
    echo "Building ${1}"
    begin_verbose
    "${CMAKE}" \
        --build "${BUILD_DIR}/${1}"
    { end_verbose; } 2>/dev/null
}

# 1 - name
function install_lib() {
    echo "Installing ${1}"
    begin_verbose
    "${CMAKE}" \
        --install "${BUILD_DIR}/${1}"
    { end_verbose; } 2>/dev/null
}


if [ "${VERBOSE}" -eq 1 ]; then
    echo "$SELF: Options"
    echo "       - targets: ${TARGETS[@]}"
    echo "       - steps: ${STEPS[@]}"
    echo "       - build type: ${BUILD_TYPE}"
    echo "       - build directory: ${BUILD_DIR}"
    echo "       - prefix directory: ${PREFIX_DIR}"
    echo "       - architectures: ${ARCHITECTURES[@]}"
    echo "       - deployment target: ${DEPLOYMENT_TARGET}"
fi

for step in "${STEPS[@]}"; do
    for target in "${TARGETS[@]}"; do
        case "${step}" in 
            configure)
                case "${target}" in
                    pdf-engine-core) configure_lib pdf-engine-core pdf-engine/core ;;
                    font-locator-core) configure_lib font-locator-core font-locator/core ;;
                esac
                ;;
            build) build_lib "${target}" ;;
            install) install_lib "${target}" ;;
        esac
    done
done
