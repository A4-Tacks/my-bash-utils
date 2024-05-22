#!/usr/bin/bash
set -o nounset

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
        prefix extra_args='' \
        prev_args='' edit='' \
        ls_opts=() ls_cmd cmd

    if ! command -v git >/dev/null; then
        printf '%q: command git not found!\n' "${FUNCNAME[0]}" >&2
        return 127
    fi

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
        [ "$ch" = $'\n' ] && printf ^M
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
				    a       add
				    R       restore
				    c       commit <args...>
				    C       switch -c
				    space   :eval git
				    :       :set extra args
				    -       :append extra optional args
				    .       :edit and running prev git command
				    e       :edit and running next git command
				    $       :edit and eval bash command
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
            H) git -a help;;
            [qQ$'\004']) return 0;;
            $'\n') git -a status;;
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
                    (exit "${tmp[-1]}")
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

            $'\020') cmd_args=(push);;&
            u) cmd_args=(remote update);;&
            [u$'\020'])
                prefix=$git_root/.git/refs/remotes/
                origs=("$prefix"*)
                PS3="select orig ($(fmt_args git "${cmd_args[@]}"))> "
                if [[ ${origs[0]} = *\* ]]; then
                    echo 'origs by empty' >&2
                    continue
                else until select orig in "${origs[@]#$prefix}"; do
                    [ "$REPLY" = 0 ] && continue 3
                    cmd_args+=("$orig")
                    break
                done do continue 2; done fi
                ;;&

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
                until select ref in "${refs[@]%$'\n'}"; do
                    [ "$REPLY" = 0 ] && continue 3
                    cmd_args+=("$ref")
                    break
                done do continue 2; done
                ;;&

            [usrimMLDP$'\020']) git -a "${cmd_args[@]}";;

            *) echo "Unknown short cmd: ${ch@Q}" >&2;;
        esac

        LEC=$?
        if [ $LEC -ne 0 ]; then
            echo "[ExitCode: $LEC]" >&2
        fi
    done
}

if [ $# -ne 0 ]; then
    cat <<- EOF
	short-git is a tool that utilizes short commands
	to improve the efficiency of simple git operations.

	USAGE: ${0##*/}
	EOF
    case "${1-}" in
        -h|--help) exit;;
        *) echo unexpected args; exit 2;;
    esac
fi

short-git
