**LICENSE**: MIT

Some personal bash scripts that may be useful.


some simple sample
-------------------------------------------------------------------------------
**short-git**

<details>
<summary>Show Code</summary>

```bash
$ bash short-git.sh
short-git> ?
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
    c       commit <args...>
    space   :eval git
    :       :set extra args
    -       :append extra optional args
    .       :edit and running prev git command
    e       :edit and running next git command
branch commands:
    s       switch
    r       rebase
    i       rebase -i
    m       merge
    M       merge --no-ff
    L       log --oneline --graph
    D       branch -d
    ^P      push <origin>
short-git> 
^M
==> status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   short-git.sh

no changes added to commit (use "git add" and/or "git commit -a")
short-git> d
==> diff
diff --git a/short-git.sh b/short-git.sh
index 8c0fda8..7a2fc2a 100644
--- a/short-git.sh
+++ b/short-git.sh
@@ -53,12 +53,14 @@ function short-git {
         printf '%q: command git not found!\n' "${FUNCNAME[0]}" >&2
         return 127
     fi
+
     git_root=$(command git rev-parse --show-toplevel) || return
 
     while
-        p="short-git> ${extra_args:+(${extra_args@Q}) }"
+        local p="short-git> ${extra_args:+(${extra_args@Q}) }"
         p+=${edit:+[+$edit] }
         read -rN1 -p"$p" ch
+        unset p
     do
         [ "$ch" = $'\n' ] && printf ^M
         echo >&2
@@ -149,22 +151,18 @@ function short-git {
                     && git -c "$cmd"
                 ;;
 
-            :)
-                if [ -z "$extra_args" ]; then
+            :)  if [ -z "$extra_args" ]; then
                     read -erp 'extra args> ' extra_args
                 else
                     extra_args=
-                fi
-                ;;
+                fi;;
 
             -) read -erp 'extra args> ' \
                 -i "${extra_args:+$extra_args }-" extra_args;;
 
-            .)
-                read -erp 'edit args> ' \
+            .) read -erp 'edit args> ' \
                     -i "$prev_args" prev_args \
-                    && git -c "$prev_args"
-                ;;
+                    && git -c "$prev_args";;
 
             e) [ -z "$edit" ] && edit=e || edit=;;
 
short-git> a
1) 'short-git.sh'
select add target> 1
==> add -- 'short-git.sh'
short-git> -
extra args> -S
short-git> ('-S') c
==> commit -S
[main 633bfce] Update short-git.sh
 1 file changed, 7 insertions(+), 9 deletions(-)
short-git> 
^M
==> status
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
short-git> l
==> log --oneline --graph --all
* 633bfce (HEAD -> main) Update short-git.sh
* e4426bf (origin/main) Add edit prev and next git commands
* c815cf3 Changed short cmd `a` to selected to finish
* 9a50873 Add args check and append extra arg for short-git.sh
* 6aea60b Add optional append arg for short-git.sh
* 46ffca8 Add extra args for short-git.sh
* efda6d0 Add git add output sorted for short-git.sh
* 1d8c919 Update short-git.sh
* a635976 Add eval git for short-git.sh
* e53538f Run git commit only in args input finished
* ff51d55 Add git add and commit for short-git.sh
* e1ddb7e Removed useless colors from README
* 6794ec1 Add a simple sample for README.md
* db35ae5 Add git show for short-git.sh
* ccb2871 add short-git.sh
* 9c03f41 Create README.md
* 29e28cf Initial commit
short-git> q
```

</details>
