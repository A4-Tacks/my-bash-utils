**LICENSE**: MIT

Some personal bash scripts that may be useful.


some simple sample
-------------------------------------------------------------------------------
**short-git**

<details>
<summary>Show Code</summary>

```bash
$ bash short-git.sh
Welcome to short-git
enter `h` or `?` show help
==> status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
short-git> ?
short-git
simple commands:
    h / ?   :show this help
    H       :show git help
    q / ^D  quit
    ^M / ^J status
    d       diff
    l       log --oneline --graph --all
    ^L      log --oneline --graph
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
    g       :append extra commit hash
    .       :edit and running prev git command
    e       :edit and running next git command
    $       :edit and eval bash command
    w       :change work directory
    o       :common operations
    f       :append extra short optional flag
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
short-git> a
1a) .           2b) ./README.md
select add target> a
==> add .
short-git> 
^M
==> status
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

short-git> f
extra short flag> S
short-git> ('-S') c
==> commit -S
[main 2795fd7] Update README.md
 1 file changed, 2 insertions(+)
short-git> l
==> log --oneline --graph --all
* 2795fd7 (HEAD -> main) Update README.md
* 61c7379 (origin/main) Add TUI select mode for short-git.sh
* 2169b8e Add select commit for short-git.sh
* 795e294 Highlight select head for short-git.sh
* d29dec2 Add very quickly select for short-git.sh
* 58fd5df Add enter auto run status for short-git.sh
* e43aa60 Revert wypt-button report request
* 92706d8 Add to next page for wypt-button
* cd238cf Add a small script, `Will you press the button`
* 5ca4939 Add common `am` cmds for short-git.sh
* eec029b Add common cmds for short-git.sh
* b6bcc29 Add f cmd for short-git.sh
* bb36442 Add log (non all) for short-git.sh
* cab7de0 Add log reset whatchanged extra refs for short-git.sh
* 4f5240c Add some common commands for short-git.sh
* b94408f Add some common ops for short-git.sh
* c1e385e Add ^P option use extend refs for short-git.sh
* 806f994 Add Unknown commands output Alert
* f27df10 Fixed select remotes for short-git.sh
* c388e3d Fixed select constant refs for short-git.sh
* a4c7d98 Removed residual P options
* 0ea5816 Fixed CR and LF
* 962c588 Changed unexpected args error messages for short-git.sh
* 2f4b558 Add builtin cd for short-git.sh
short-git> q
```

</details>
