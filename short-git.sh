#!/usr/bin/bash
set -o nounset

function fmt_args {
    [ $# -eq 0 ] && return
    local -i h=0
    local arg a b f
    for arg in "$@"; do
        a=${arg@Q}
        b=$(printf %q "$arg")
        if ((h++)); then
            f=' %s'
        else
            f='%s'
        fi
        if [ ${#a} -le ${#b} ]; then
            printf "$f" "$a"
        else
            printf "$f" "$b"
        fi
    done
}

function git {
    local arg a b
    printf '==> ' >&2
    fmt_args "$@" >&2
    echo >&2
    command git "$@"
}

function short-git {
    local ch ref refs PS3 cmd_args LEC git_root orig origs prefix
    if ! command -v git >/dev/null; then
        printf '%q: command git not found!\n' "${FUNCNAME[0]}" >&2
        return 127
    fi
    git_root=$(command git rev-parse --show-toplevel) || return

    while read -rN1 -p'short-git> ' ch; do
        echo >&2
        case "${ch}" in
            [h?])
                cat <<- EOF
				short-git
				simple commands:
				    h / ?   :show this help
				    H       :show git help
				    q / ^D  quit
				    ^M      status
				    d       diff
				    l       log --oneline --graph --all
				    p       push
				    u       remote update
				    S       show
				branch commands:
				    s       switch
				    r       rebase
				    i       rebase -i
				    m       merge
				    M       merge --no-ff
				    L       log --oneline --graph
				    D       branch -d
				    ^P      push <origin>
				EOF
                ;;
            H) git help;;
            [qQ$'\004']) return 0;;
            $'\n') git status;;
            d) git diff;;
            l) git log --oneline --graph --all;;
            p) git push;;
            S) git show;;

            $'\020') cmd_args=(push);;&
            u) cmd_args=(remote update);;&
            [u$'\020'])
                prefix=$git_root/.git/refs/remotes/
                origs=("$prefix"*)
                PS3="select orig ($(fmt_args git "${cmd_args[@]}"))> "
                if [[ ${origs[0]} = *\* ]]; then
                    echo 'origs by empty' >&2
                    continue
                else select orig in "${origs[@]#$prefix}"; do
                    cmd_args+=("$orig")
                    break
                done fi
                ;;&

            u) git "${cmd_args[@]}";;

            s) cmd_args=(switch);;&
            r) cmd_args=(rebase);;&
            i) cmd_args=(rebase -i);;&
            m) cmd_args=(merge);;&
            M) cmd_args=(merge --no-ff);;&
            L) cmd_args=(log --oneline --graph);;&
            D) cmd_args=(branch -d);;&
            [srimMLDP$'\020'])
                mapfile refs < <(
                    command git for-each-ref --format="%(refname:strip=2)" \
                        'refs/heads/*' 'refs/heads/*/**'
                )
                PS3="select ref ($(fmt_args git "${cmd_args[@]}"))> "
                if [ ${#refs[@]} -eq 0 ]; then
                    echo 'refs by empty' >&2
                    continue
                fi
                select ref in "${refs[@]%$'\n'}"; do
                    git "${cmd_args[@]}" "$ref"
                    break
                done
                ;;

            *) echo "Unknown short cmd: ${ch@Q}" >&2;;
        esac

        LEC=$?
        if [ $LEC -ne 0 ]; then
            echo "[ExitCode: $LEC]" >&2
        fi
    done
}

short-git
