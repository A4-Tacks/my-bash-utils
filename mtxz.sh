#!/usr/bin/bash
# shellcheck disable=SC2206
set -o nounset
#set -o pipefail

level=''
keep=''
threads=6

OPTIND=1
args=()
while case "${!OPTIND---}" in
    -*?)false;;
    *)  args+=("${!OPTIND}"); ((++OPTIND)); continue
esac || getopts hkT:0123456789 opt; do case "$opt" in
    h)
        printf 'Usage: %q [Options]\n' "${0##*/}"
        echo 'Multiple process xz/unxz/zstd/unzstd etc'
        echo
        printf '%s\n' \
            'Options:' \
            '    -#                 0-9 compression level' \
            '    -T                 threads number [default: 6]' \
            '    -k                 keep remove origin file' \
            '    -h                 show help' \
            && exit
        ;;
    T) threads=$OPTARG;;
    k) keep=1;;
    0|1|2|3|4|5|6|7|8|9) level=${level:--}$opt;;
    :|\?)
        ((--OPTIND <= 0)) && OPTIND=1
        printf '%q: parse args failed, near by %q\n' "$0" "${!OPTIND}" >&2
        exit 2
esac done
set -- "${args[@]}" "${@:OPTIND}"

if ! [[ $threads =~ ^[1-9][0-9]*$ ]]; then
    printf '%q: invalid threads number: %q\n' "$0" "$threads" >&2
    exit 2
fi

hash seq mkfifo mktemp || exit

if [ -n "$keep" ]; then
    xz_keep=-k
    zst_keep=''
else
    xz_keep=''
    zst_keep=--rm
fi

case "${0##*/}" in
    mgz|mtgz|mgzip|mtgzip)
        args=(gzip $xz_keep $level);;
    mungz|mtungz|mungzip|mgunzip|mtungzip|mtgunzip)
        args=(gunzip $xz_keep $level);;
    mxz|mtxz)
        args=(xz $xz_keep $level);;
    munxz|mtunxz)
        args=(unxz $xz_keep $level);;
    zst|mzst|mtzst|mzstd|mtzstd)
        args=(zstd $zst_keep --no-progress -q $level);;
    munzst|munzstd|mtunzst|mtunzstd)
        args=(unzstd $zst_keep --no-progress -q $level);;
    *)
        printf '%q: invalid program name (%q), try ln -s\n' "$0" "$0" >&2
        exit 3
esac

for file; do
    if ! test -e "$file"; then
        printf '%q: path not exists: %q\n' "$0" "$file" >&2
        exit 1
    fi
done

tmp=$(mktemp -d --tmp mtxz.XXXXXXXXXX) || exit
trap 'wait; rm -r -- "$tmp"' exit
readonly tmp

mkfifo -- "$tmp/fifo" || exit
exec 3<>"$tmp/fifo"
echo 0 > "$tmp/exitcode"

hash "${args[0]}"

echo "Command: ${args[*]@Q}"

printf '%.0s\n' $(seq "$threads") >&3

i=0
for file; do
    read -ru3
    echo "[$((++i))/$#] ${file@Q}"
    {
        "${args[@]}" -- "$file" || echo $? > "$tmp/exitcode"
        echo >&3
    }&
done

echo 'wait for subprocessors exit...'
for i in $(seq "$threads"); do
    read -ru3
    printf '\e[K%s\r' "$i/$threads"
done

wait
exit "$(< "$tmp/exitcode")"
