#!/usr/bin/bash
set -o nounset

# This script references a portion of the git own bash completion script to obtain similar logic

shopt -s extglob

readonly CONST_REFS=(
    HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD REBASE_HEAD
    CHERRY_PICK_HEAD REVERT_HEAD BISECT_HEAD AUTO_MERGE
)

readonly COMMON_OPERATIONS=( # {{{
    'rebase --'{continue,abort,skip,quit,edit-todo,apply}
    'reflog'
    'diff --staged'
    'commit --amend'
    'log --stat --dirstat --graph --all'
    'log --show-signature --graph --all'
    'am --'{continue,abort,skip,quit}
    'merge --'{continue,abort,quit}
    'clean -i'
) # }}}

function code { # {{{
    return "${1:-$?}"
} # }}}

function fmt_args { # {{{
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
} # }}}

declare -A SELECT_MAP=()

readonly SELECT_KEY_LIST=( # {{{
    1a:a 2b:b 3c:c 4d:d 5e:e 6f:f 7g:g 8h:h 9i:i
    {j..z}
    {A..Z}
    $'^A:\cA' $'^B:\cB' $'^E:\cE' $'^F:\cF'
    $'^G:\cG' $'^H:\cH' $'^I:\cI' $'^K:\cK'
    $'^L:\cL' $'^N:\cN' $'^O:\cO' $'^P:\cP'
    $'^R:\cR' $'^T:\cT' $'^U:\cU' $'^V:\cV'
    $'^W:\cW' $'^X:\cX' $'^Y:\cY'
) # }}}
readonly WSELECT_KEY_LIST=( # {{{
    {a..z}
) # }}}

function git_prev { # {{{
    command git rev-parse --abbrev-ref --symbolic-full-name '@{-1}'
} # }}}

function qselect { # {{{
    local i ch
    REPLY=''
    [ $# -ne 0 ] || return 0
    SELECT_MAP=()
    if [ -n "${TUI_BIN-}" ]; then # TUI mode {{{
        local -i high=$(($# + 8)) cols=0 lsthigh=0 j=0
        local args=() key
        for i in "$@"; do
            key=${WSELECT_KEY_LIST[j]-.}$((++j))
            args+=("$key" "$i")
            [ $((${#key} + ${#i})) -gt $cols ] && cols=${#key}+${#i}
        done
        [ $high -gt $LINES ] && high=LINES
        ((cols < 15)) && cols=15
        ((cols < ${#PS3})) && cols=${#PS3}
        ((cols <<= 1)) # 考虑可能的全角字符
        cols+=12; ((cols > COLUMNS)) && cols=COLUMNS
        lsthigh="$# > high-8 ? high-8 : $#"
        REPLY=$(
            "$TUI_BIN" --menu "$PS3" $high $cols $lsthigh "${args[@]}" \
                3>&1 >&2 2>&3
        ) && REPLY=${REPLY:1} && REPLY=${!REPLY}
        return
    fi # }}}
    if [ $# -ge ${#SELECT_KEY_LIST[*]} ]; then # Normal mode {{{
        select ch in "$@"; do
            if [[ $REPLY =~ ^[0-9]+$ ]]; then
                if [ "${REPLY}" = 0 ]; then
                    REPLY=''
                    return
                fi
                REPLY=${!REPLY}
                break
            elif [[ $REPLY = , ]]; then
                REPLY=$(git_prev)
                return
            elif [[ $REPLY = a ]]; then
                REPLY=$1
                return
            else
                echo "Inavlid input ${REPLY@Q}, expect number"
            fi
        done
        return
    fi # }}}
    while true; do # Quick mode {{{
        i=0
        for ch in "${SELECT_KEY_LIST[@]}"; do
            ((i++ < $#)) || break
            SELECT_MAP[${ch##*:}]="${!i}"
            printf '%2s) %s\n' "${ch%:*}" "${!i}"
        done > >(column | grep --color=auto $'\(^\|\t\)[^)]\+)')
        wait

        printf '%s\e7' "$PS3"
        while true; do
            read -rN1 || return $?
            printf '\e[K'
            case "$REPLY" in
                $'\n') continue 2;;
                $'\cD') echo; return 1;;
                0|' ') echo; REPLY=''; return 0;;
                ,) echo; REPLY=$(git_prev); return 0;;
                [0-9]) REPLY=${SELECT_KEY_LIST[REPLY - 1]##*:};;
                $'\t') printf '\e8^I';;
            esac
            if [ -n "${SELECT_MAP[$REPLY]-}" ]; then
                REPLY=${SELECT_MAP[$REPLY]}
                echo; return
            fi
            printf ' %s\e[K\e8' 'is invalid input'
        done
    done # }}}
} # }}}

function git { # {{{
    local arg opt bound=''

    unset prev_args
    OPTIND=1
    while getopts abc opt; do case "$opt" in
        (b) bound=' --';;
        (c) prev_args="${*:OPTIND}"; break;;
        (a) prev_args="$(fmt_args "${@:OPTIND}")"; break;;
        *)
            ((--OPTIND <= 0)) && OPTIND=1
            git=; ${git:?invalid args: ${!OPTIND@Q}}; exit 200;;
    esac done

    if [ -n "${edit-}" ]; then
        read -erp "==> " -i "$prev_args" prev_args || return
        printf '\e[A\e[K'
        edit=
    fi

    prev_args=$prev_args${extra_args:+ $extra_args}
    extra_args=''

    printf '==> %s\n' "$prev_args" >&2

    history -s -- "$prev_args"
    eval "command git $prev_args$bound"
} # }}}

function git_root { # {{{
    command git rev-parse --show-toplevel
} # }}}

function upstream { # {{{
    command git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
} # }}}

function short-git { # {{{
    local ch ref refs PS3 cmd_args cmd_args_post LEC git_root git_dir \
        extra_args='' gitf_flags='' \
        prev_args='' edit='' \
        ls_opts=() ls_cmd cmd ref_pats use_c_refs used_c_refs \
        p prompt remote branch clean_stat

    if ! command -v git >/dev/null; then
        printf '%q: command git not found!\n' "${FUNCNAME[0]}" >&2
        return 127
    fi

    # abs path
    if [ -n "${GIT_DIR-}" ]; then
        git_dir=$GIT_DIR
    else
        git_root=$(git_root) || return
        git_dir=$git_root/.git
    fi


	cat <<- 'EOF'
	Welcome to short-git
	enter `h` or `?` show help
	EOF

    prompt='short-git> '

    ( # 可取消的 git status , 考虑到有些仓库执行 status 耗时过久
        status_msg=$(command git -c color.status=always status) || exit
        printf '\r\e[J%s\n%s' "$status_msg" "$prompt"
    ) &
    clean_stat="if hash pkill; then pkill -P $!; else kill $!; fi; wait $!"
    # shellcheck disable=2064
    trap "$clean_stat" exit

    while
        p="$prompt${extra_args:+(${extra_args@Q}) }"
        p+=${edit:+[+$edit] }
        read -rN1 -p"$p" ch
    do
        if [ -n "$clean_stat" ]; then
            trap '' exit
            eval "$clean_stat"
            clean_stat=''
        fi
        [ "$ch" = $'\n' ] && printf ^M # \r会自动转成\n
        echo >&2
        case "${ch}" in
            [h?]) # {{{
                cat <<- EOF
				short-git
				simple commands:
				    h / ?   :show this help
				    H       :show git help
				    q / ^D  quit
				    ^M / ;  status
				    comma   switch -
				    d       diff
				    l       log --oneline --graph --all
				    ^L      log --oneline --graph
				    p       push
				    P       push -u <origin> {current}
				    ^P      push <origin>
				    ^Y      push --delete {upstream} {current}
				    Y       :delete merged upstream and local branches
				    ^R      rebase {upstream}/{current}
				    ^I      rebase -i {upstream}/{current}
				    ^U      remote update {upstream}
				    k       checkout <remote-branch> --
				    u       remote update
				    S       show HEAD
				    g       show <commit:try>
				    a       add
				    A       add -u
				    E       add --edit
				    ^E      add --patch
				    R       restore
				    ^A      restore --staged
				    c       commit
				    b       commit -anm TODO --no-gpg-sign --branch
				    B       reset --soft HEAD^ && commit --amend
				    C       switch -c
				    X       reset --hard HEAD^
				    W       whatchanged --graph --oneline
				    space   :eval git
				    :       :set extra args
				    -       :append extra optional args
				    .       :edit and running prev git command
				    e       :edit and running next git command
				    $       :edit and eval bash command
				    w       :change work directory
				    o       :common operations
				    O       :edit raw commit message
				    f       :append extra short optional flag
				branch commands:
				    s       switch
				    r       rebase
				    i       rebase -i
				    m       merge
				    M       merge --no-ff
				    L       log --oneline --graph
				    D       branch -d
				    t       reset
				    T       reset --hard
				    ^W      whatchanged --graph --oneline
				EOF
                ;; # }}}
            H) git -a help;;
            $'\e') read -rt0.1;&
            [qQ$'\cd']) return 0;;
            [$'\r\n;']) git -a status;;
            ,) git -a switch -;;
            d) git -a diff;;
            l) git -a log --oneline --graph --all;;
            $'\cL') git -a log --oneline --graph;;
            p) git -a push;;
            $'\cY')
                if ref=$(upstream); then
                    git -a status
                    read -rp "==> Yank from ${ref@Q}? [Y/n] " REPLY
                    [[ "$REPLY" = [Yy] ]] &&
                        git -a push "${ref%%/*}" --delete "$(command git branch --show-current)"
                fi
                ;;
            Y)
                ref=$(command git show --format='%H' --no-patch)
                read -rd '' -a refs < <(
                    command git for-each-ref --merged HEAD \
                        'refs/remotes/*/*' --format='%(objectname) %(refname:strip=2)' |
                        awk -vr="$ref" '!x[$1]++&&$1!=r{print$2}'
                )
                PS3="select delete branch> "
                if qselect "${refs[@]}" && [ -n "$REPLY" ]; then
                    while read -r ref; do
                        git -a branch --delete "$ref"
                    done < <(
                        command git for-each-ref --points-at="$REPLY" \
                            'refs/heads/*' --format='%(refname:strip=2)'
                    )

                    remote=${REPLY%%/*}
                    branch=${REPLY#*/}
                    git -a push "$remote" --delete "$branch"
                fi
                ;;
            $'\cR')
                ref=$(upstream) &&
                    git -a rebase "${ref%%/*}/$(command git branch --show-current)";;
            $'\cI')
                ref=$(upstream) &&
                    git -a rebase -i "${ref%%/*}/$(command git branch --show-current)";;
            $'\cU')
                ref=$(upstream) &&
                    git -a remote update "${ref%%/*}";;
            S) git -ba show HEAD;;
            k)
                local -a branches sorted_branches exclude_branches
                read -rd '' -a branches < <(
                    command git branch -a --format='%(refname:strip=2)' |
                        grep /
                )
                read -rd '' -a exclude_branches < <(
                    command git for-each-ref --format="-e/%(refname:strip=2)" \
                        'refs/heads/*' 'refs/heads/*/**'
                )
                mapfile -td '' sorted_branches < <(
                    printf '%q\0' "${branches[@]}" | sort -zu |
                        grep -vz "${exclude_branches[@]}" -e/HEAD
                )
                PS3="select checkout branch> "
                qselect "${sorted_branches[@]}" && [ -n "$REPLY" ] &&
                    git -a checkout --track "$REPLY" --
                unset branches sorted_branches exclude_branches
                ;;
            A) git -a add -vu | sed 's/^/    /';;
            E) git -a add --edit;;
            $'\cE') git -a add --patch;;
            $'\cA')
                local staged_files
                mapfile -td '' staged_files < <(
                    command git -c core.quotePath=false \
                        diff --name-only --staged --relative -z
                )
                [ ${#staged_files[@]} -ne 0 ] && staged_files+=(.)
                PS3="select restore --staged target> "
                qselect "${staged_files[@]}" && [ -n "$REPLY" ] &&
                    git -a restore --staged "$REPLY"
                unset staged_files
                ;;
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
                mapfile -td '' tmp < <(
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
                    mapfile -td '' sorted_files < <(\
                        printf '%q\0' "${!files[@]}" | sort -z
                    )
                    [ ${#sorted_files[@]} -eq 1 ] \
                        && [ "${sorted_files[0]}" = "''" ] \
                        && sorted_files=()
                    PS3="select $ls_cmd target> "
                    qselect "${sorted_files[@]}" &&
                        git -c "$ls_cmd" "$REPLY" # 在之前进行了可重用
                    unset file files tmp sorted_files
                fi
                ;;
            c) git -c commit;;
            b) git -a commit -anm TODO --no-gpg-sign --branch;;
            B) git -a reset --soft HEAD^ && git -a commit --amend --no-edit;;
            C)
                local name
                read -erp 'git switch -c ' name \
                    && git -a switch -c "$name"
                unset name
                ;;
            X)  git -a status &&
                    read -rp "==> reset to HEAD^ ? [Y/n]" REPLY &&
                    [[ -z $REPLY || $REPLY = [Yy] ]] && git -a reset --hard HEAD^
                ;;

            W)
                git -a whatchanged --graph --oneline
                ;;

            ' ')
                read -erp '$ git ' cmd \
                    && git -c "$cmd"
                ;;

            :)  if [ -z "$extra_args" ]; then
                    read -erp 'extra args> ' extra_args
                else
                    extra_args=
                fi;;

            -) read -erp 'extra args> ' \
                -i "${extra_args:+$extra_args }-" extra_args;;

            g)  prev_args='show '
                until if read -erp '$ git show ' -i "${prev_args##show*( )}" prev_args
                      then git -c show "$prev_args"
                      fi do :;done;;

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
                            LEC=$?
                            git_root=$(git_root) || return
                            printf 'current pwd: %q\n' "$(pwd)"
                            printf 'git root: %q\n' "${git_root}"
                            code $LEC
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
                qselect "${COMMON_OPERATIONS[@]}" &&
                    [ -n "${REPLY}" ] &&
                    git -c "$REPLY"
                ;;

            O) git -a commit --amend --cleanup=verbatim --no-status;;

            f)
                local flag
                read -N1 -rp 'extra short flag> ' flag
                case "$flag" in
                    [$' \t\r\cD']) echo >&2;&
                    $'\n')          code 1;;
                    *)
                        extra_args+=" -$flag"
                        extra_args=${extra_args# }
                        echo >&2
                        ;;
                esac
                ;;

            *) cmd_args_post=() gitf_flags='';;&

            $'\cP') cmd_args=(push);;&
            P) cmd_args=(push -u); cmd_args_post=("$(command git branch --show-current)");;&
            u) cmd_args=(remote update);;&
            [uP$'\cP'])
                PS3="select orig ($(fmt_args git "${cmd_args[@]}"))> "
                if qselect $(command git remote); then
                    [ -z "${REPLY}" ] && continue 2
                    cmd_args+=("$REPLY")
                else
                    continue
                fi
                ;;&

            *)
                ref_pats=('refs/heads/*' 'refs/heads/*/**')
                use_c_refs=1
                ;;&
            [L]) ref_pats+=("refs/tags/*" "refs/tags/*/**");;&
            [rimMLtT$'\cW']) ref_pats+=("refs/remotes/*" "refs/remotes/*/**");;&
            [rmM])
                ref_pats+=(--no-merged HEAD)
                ;;&
            [sDrimM]) use_c_refs=0;;&
            [tTL$'\cW']) gitf_flags+=b;;&
            s) cmd_args=(switch);;&
            r) cmd_args=(rebase);;&
            i) cmd_args=(rebase -i);;&
            m) cmd_args=(merge --no-edit);;&
            M) cmd_args=(merge --no-ff --no-edit);;&
            L) cmd_args=(log --oneline --graph);;&
            D) cmd_args=(branch -d);;&
            t) cmd_args=(reset);;&
            T) cmd_args=(reset --hard);;&
            $'\cW') cmd_args=(whatchanged --graph --oneline);;&
            [srimMLDtT$'\cW'])
                mapfile -t refs < <(
                    command git for-each-ref --format="%(objectname) %(refname:strip=2)" \
                        "${ref_pats[@]}" |
                        awk '!x[$1]++||$2!~"/"{print$2}'
                )
                PS3="select ref ($(fmt_args git "${cmd_args[@]}"))> "
                if [ ${#refs[@]} -eq 0 ]; then
                    echo 'refs by empty' >&2
                    continue
                fi
                used_c_refs=()
                [ "${use_c_refs-}" = 1 ] &&
                    for ref in "${CONST_REFS[@]}"; do
                        [ -e "$git_dir/$ref" ] && used_c_refs+=("$ref")
                    done
                if qselect "${used_c_refs[@]}" "${refs[@]%$'\n'}"; then
                    [ -z "${REPLY}" ] && continue 2
                    cmd_args+=("$REPLY")
                else
                    continue
                fi
                ;;&

            [usrimMLDtTP$'\cP\cW'])
                git -${gitf_flags}a "${cmd_args[@]}" "${cmd_args_post[@]}";;

            *) echo $'\a'"Unknown short cmd: ${ch@Q}" >&2;;
        esac

        LEC=$?
        if [ $LEC -ne 0 ]; then
            echo "[ExitCode: $LEC]" >&2
        fi
    done
} # }}}

OPTIND=1
while getopts h-wn opt; do case "$opt" in
    h|-)
        cat <<- EOF
		short-git is a tool that utilizes short commands
		to improve the efficiency of simple git operations.

		USAGE: ${0##*/} [-w] [-h | --help]

		OPTIONS:
		    -w          use whiptail (TUI utils) select
		    -n          for naked repo, set GIT_DIR=.
		EOF
        exit;;
    w)
        TUI_BIN=whiptail
        if ! hash "$TUI_BIN"; then
            echo "${TUI_BIN} not found" >&2
            exit 127
        fi
        export NEWT_COLORS='root=,color8;actsellistbox=color15,;actlistbox=,color8';;
    n)  GIT_DIR=$(pwd);;
    :|\?)
        ((--OPTIND <= 0)) && OPTIND=1
        printf '%q: parse args failed, near by %q\n' "$0" "${!OPTIND}" >&2
        exit 2
esac done
set -- "${@:OPTIND}"
if [ $# -ne 0 ]; then
    printf '%q: unexpected arg %q\n' "$0" "$1" >&2
    exit 2
fi

short-git
