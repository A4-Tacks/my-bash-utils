#!/usr/bin/bash
set -o nounset

# This script references a portion of the git own bash completion script to obtain similar logic

readonly CONST_REFS=(
    HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD REBASE_HEAD
    CHERRY_PICK_HEAD REVERT_HEAD BISECT_HEAD AUTO_MERGE
)

readonly COMMON_OPERATIONS=(
    'rebase --'{continue,abort,skip,quit,edit-todo,apply}
    reflog
    'diff --staged'
    'commit --amend'
)

function code {
    return "${1:-$?}"
}

function fmt_args {
    [ $# -eq 0 ] && return
    local -i h=0
    local arg a b
    for arg in "$@"; do
        a=${arg@Q}
        b=$(printf %q "$arg")
        ((h++)) && printf ' '
        if [ ${#a} -le ${#b} ]; then
            printf %s "$a"
        else
            printf %s "$b"
        fi
    done
}

function git {
    local arg a b LEC

    case "${1?}" in
        -c)
            shift
            prev_args="$*${extra_args:+ $extra_args}"
            ;;
        -a)
            shift
            prev_args="$(fmt_args "$@")${extra_args:+ $extra_args}"
            ;;
        *) git=; ${git:?invalid args: ${1@Q}};;
    esac

    if [ -n "${edit-}" ]; then
        read -erp "==> " -i "$prev_args" prev_args
        edit=
    else
        printf '==> %s\n' "$prev_args" >&2
    fi

    eval "command git $prev_args"
    LEC=$?
    extra_args=
    return $LEC
}

function short-git {
    local ch ref refs PS3 cmd_args LEC git_root orig origs \
        extra_args='' \
        prev_args='' edit='' \
        ls_opts=() ls_cmd cmd ref_pats use_c_refs used_c_refs

    if ! command -v git >/dev/null; then
        printf '%q: command git not found!\n' "${FUNCNAME[0]}" >&2
        return 127
    fi

    # abs path
    git_root=$(command git rev-parse --show-toplevel) || return


	cat <<- 'EOF'
	Welcome to short-git
	enter `h` or `?` show help
	EOF

    while
        local p="short-git> ${extra_args:+(${extra_args@Q}) }"
        p+=${edit:+[+$edit] }
        read -rN1 -p"$p" ch
        unset p
    do
        [ "$ch" = $'\n' ] && printf ^M # \r会自动转成\n
        echo >&2
        case "${ch}" in
            [h?])
                cat <<- EOF
				short-git
				simple commands:
				    h / ?   :show this help
				    H       :show git help
				    q / ^D  quit
				    ^M / ^J status
				    d       diff
				    l       log --oneline --graph --all
				    p       push
				    u       remote update
				    S       show
				    a       add
				    R       restore
				    c       commit <args...>
				    C       switch -c
				    W       whatchanged --graph --oneline
				    space   :eval git
				    :       :set extra args
				    -       :append extra optional args
				    .       :edit and running prev git command
				    e       :edit and running next git command
				    $       :edit and eval bash command
				    w       :change work directory
				    o       :common operations
				branch commands:
				    s       switch
				    r       rebase
				    i       rebase -i
				    m       merge
				    M       merge --no-ff
				    L       log --oneline --graph
				    D       branch -d
				    ^P      push <origin>
				    t       reset
				    T       reset --hard
				    ^W      whatchanged --graph --oneline
				EOF
                ;;
            H) git -a help;;
            [qQ$'\004']) return 0;;
            [$'\r\n']) git -a status;;
            d) git -a diff;;
            l) git -a log --oneline --graph --all;;
            p) git -a push;;
            S) git -a show;;
            a)
                ls_opts=(
                    --others
                    --modified
                    --directory
                    --no-empty-directory
                    --exclude-standard
                )
                ls_cmd=add
                ;;&
            R)
                ls_opts=(
                    --modified
                    --no-empty-directory
                    --exclude-standard
                )
                ls_cmd=restore
                ;;&
            [aR])
                local file tmp
                local -A files
                mapfile -d '' tmp < <(
                    command git ls-files "${ls_opts[@]}" -z
                    printf '%d\0' $?
                )
                if [ "${tmp[-1]}" -ne 0 ]; then
                    code "${tmp[-1]}"
                else
                    files=()
                    for file in "${tmp[@]::${#tmp[@]}-1}"; do
                        file=./$file
                        files[$file]=0
                        while [[ $file = */?* ]]; do
                            file=${file%/?*}
                            files[$file]=0
                        done
                    done

                    local -a sorted_files
                    mapfile -d '' sorted_files < <(\
                        printf '%q\0' "${!files[@]}" | sort -z
                    )
                    [ ${#sorted_files[@]} -eq 1 ] \
                        && [ "${sorted_files[0]}" = "''" ] \
                        && sorted_files=()
                    PS3="select $ls_cmd target> "
                    select file in "${sorted_files[@]}"; do
                        [ "$REPLY" = 0 ] && break
                        if [ -z "$file" ]; then
                            echo invalid input >&2
                            continue
                        fi
                        git -c "$ls_cmd" "$file" # 在之前进行了可重用
                        break
                    done
                    unset file files tmp sorted_files
                fi
                ;;
            c) git -c commit;;
            C)
                local name
                read -erp 'git switch -c ' name \
                    && git -a switch -c "$name"
                unset name
                ;;

            W)
                git -a whatchanged --graph --oneline
                ;;

            ' ')
                read -erp 'git ' cmd \
                    && git -c "$cmd"
                ;;

            :)  if [ -z "$extra_args" ]; then
                    read -erp 'extra args> ' extra_args
                else
                    extra_args=
                fi;;

            -) read -erp 'extra args> ' \
                -i "${extra_args:+$extra_args }-" extra_args;;

            .) read -erp 'edit args> ' \
                    -i "$prev_args" prev_args \
                    && git -c "$prev_args";;

            e) [ -z "$edit" ] && edit=e || edit=;;

            $) read -erp'$ ' cmd && eval "$cmd";;
            w)
                echo 'r(git root) .(parent dir) space(custom) p(-)' >&2
                if read -rN1 -p'change to> '; then
                    echo >&2
                    case "$REPLY" in
                        r) REPLY=$git_root;;&
                        .) REPLY=..;;&
                        ' ')
                            read -erp'change to dir> '
                            LEC=$?
                            code $LEC
                            ;;&
                        p) REPLY=-;;&
                        ['r. p'])
                            code && cd -- "$REPLY" > /dev/null \
                                && command git status -s >/dev/null \
                                && pwd \
                                || cd - \
                                || return
                            ;;
                        *)
                            echo "Unknown cd target: ${REPLY@Q}" >&2
                            code 2
                            ;;
                    esac
                fi
                ;;

            o)
                PS3="select cmd> "
                select cmd in "${COMMON_OPERATIONS[@]}"; do
                    git -c "$cmd"
                    break
                done
                ;;

            $'\020') cmd_args=(push);;&
            u) cmd_args=(remote update);;&
            [u$'\020'])
                PS3="select orig ($(fmt_args git "${cmd_args[@]}"))> "
                origs=$(command git remote)
                until select orig in $origs; do
                    [ "$REPLY" = 0 ] && continue 3
                    cmd_args+=("$orig")
                    break
                done do continue 2; done
                ;;&

            *)
                ref_pats=('refs/heads/*' 'refs/heads/*/**')
                use_c_refs=1
                ;;&
            [rimMLtT$'\020\027'])
                ref_pats=(
                    "refs/tags/*" "refs/tags/*/**"
                    "refs/heads/*" "refs/heads/*/**"
                    "refs/remotes/*" "refs/remotes/*/**"
                )
                ;;&
            [sD]) use_c_refs=0;;&
            s) cmd_args=(switch);;&
            r) cmd_args=(rebase);;&
            i) cmd_args=(rebase -i);;&
            m) cmd_args=(merge);;&
            M) cmd_args=(merge --no-ff);;&
            L) cmd_args=(log --oneline --graph);;&
            D) cmd_args=(branch -d);;&
            t) cmd_args=(reset);;&
            T) cmd_args=(reset --hard);;&
            $'\027') cmd_args=(whatchanged --graph --oneline);;&
            [srimMLDtT$'\020\027'])
                mapfile refs < <(
                    command git for-each-ref --format="%(refname:strip=2)" \
                        "${ref_pats[@]}"
                )
                PS3="select ref ($(fmt_args git "${cmd_args[@]}"))> "
                if [ ${#refs[@]} -eq 0 ]; then
                    echo 'refs by empty' >&2
                    continue
                fi
                used_c_refs=()
                [ "${use_c_refs-}" = 1 ] &&
                    for ref in "${CONST_REFS[@]}"; do
                        [ -e "$git_root/.git/$ref" ] && used_c_refs+=("$ref")
                    done
                until select ref in "${used_c_refs[@]}" "${refs[@]%$'\n'}"; do
                    [ "$REPLY" = 0 ] && continue 3
                    cmd_args+=("$ref")
                    break
                done do continue 2; done
                ;;&

            [usrimMLDtT$'\020\027']) git -a "${cmd_args[@]}";;

            *) echo $'\a'"Unknown short cmd: ${ch@Q}" >&2;;
        esac

        LEC=$?
        if [ $LEC -ne 0 ]; then
            echo "[ExitCode: $LEC]" >&2
        fi
    done
}

if [ $# -ne 0 ]; then
    case "${1-}" in
        -h|--help);;
        *) echo Error: unexpected args: "${*@Q}"; exit 2;;
    esac
    cat <<- EOF
	short-git is a tool that utilizes short commands
	to improve the efficiency of simple git operations.

	USAGE: ${0##*/}
	EOF
    exit
fi

short-git
