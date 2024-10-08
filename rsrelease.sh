#!/usr/bin/bash
set -o nounset
set -o errtrace
set -o pipefail
function CATCH_ERROR {
    local __LEC=$? __i
    echo "Traceback (most recent call last):" >&2
    for ((__i = ${#FUNCNAME[@]} - 1; __i >= 0; --__i)); do
        printf '  File %q line %s in %q\n' >&2 \
            "${BASH_SOURCE[$__i]}" \
            "${BASH_LINENO[$__i]}" \
            "${FUNCNAME[$__i]}"
    done
    echo "Error: [ExitCode: ${__LEC}]" >&2
    exit "${__LEC}"
}
trap CATCH_ERROR ERR

function run {
    local __LEC=0
    echo "===> ${*@Q}" >&2
    "$@" || {
        __LEC=$?
        echo "Failed ($__LEC): ${*@Q}"
    }
    return $__LEC
}

run hash cargo jq

COMPILE_TARGET=aarch64-unknown-linux-musl
HASHER=sha256sum

OPTIND=1
while getopts ht:H: opt; do case "$opt" in
    h)
        printf 'Usage: %q [Options]\n\n' "${0##*/}"
        printf '%s\n' \
            'Options:' \
            '    -t <target>        set target' \
            '    -H <hasher>        set hasher' \
            '    -h                 show help' \
            && exit
        ;;
    t)
        COMPILE_TARGET=$OPTARG
        ;;
    H)
        HASHER=$OPTARG
        ;;
    *)
        ((--OPTIND <= 0)) && OPTIND=1
        printf '%q: parse args failed, near by %q\n' "$0" "${!OPTIND}" >&2
        exit 2
esac done
set -- "${@:OPTIND}"

NAME=$(cargo read-manifest | jq .name -r)
VERSION=$(cargo read-manifest | jq .version -r)

run hash "${HASHER:?}"

TARGET_DIR="target/${COMPILE_TARGET:?}/"
RENAMED_NAME="${NAME:?}_${VERSION:?}_${COMPILE_TARGET:?}"

run cargo build --release --target="${COMPILE_TARGET}" "$@"
run test -d "${TARGET_DIR}"

run cd "${TARGET_DIR}/release/" || exit

run test -f "${NAME}"
run test -r "${NAME}"
run test -x "${NAME}"

TARPKG_NAME="${RENAMED_NAME}.tar"
XZPKG_NAME="${TARPKG_NAME}.xz"

[ -f "${TARPKG_NAME}" ] && run rm "${TARPKG_NAME}"
[ -f "${XZPKG_NAME}" ] && run rm "${XZPKG_NAME}"

run tar -cf "${TARPKG_NAME}" "${NAME}"
run xz -9evvT1 "${TARPKG_NAME}"

HASHER_NAME="${HASHER##*/}"
HASH_OUT="$(run "${HASHER}" "${XZPKG_NAME}")"
HASH_OUT_FILE="${XZPKG_NAME}.${HASHER_NAME}"
run echo "${HASH_OUT}" > "${HASH_OUT_FILE}"
