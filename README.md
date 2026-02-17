**LICENSE**: MIT

Some personal bash scripts that may be useful.


Some Simple Sample
===============================================================================

github scripts
-------------------------------------------------------------------------------
As a supplement to github-cli

- github-comment-review: Add a reply comment for review comments url
- github-issues: Similar `gh issue list`, but cleanly labels, pullRef/assign and show comments count
- github-reactions: Show user names of reactions, and send a new reactions
- github-timeline: Show timeline and event of pulls or issues
- github-request-review: Request reviewer
- github-reviews: Show comments, reviews and review comments
- github-start-review: Create some review on diff hunk


git scripts
-------------------------------------------------------------------------------
- git-shallow: Quickly add a grafted commit (which may disrupt the unshallow)
- git-fc: Using a short reference to fetch a local commit
- git-showtool: A `git difftool commit^ commit` wrapper
- git-pretty-graph: git log pager, improve graph lines


short-git
-------------------------------------------------------------------------------
Perform simple git operations with fewer key interactions

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


replline
-------------------------------------------------------------------------------
Quickly and repeatedly execute certain commands, with independent history

<details>
<summary>Show Code</summary>

```
$ replline -a jq -n
REPL for jq -n
jq> .
null
jq> range(7)|.*3
0
3
6
9
12
15
18
jq> range(2;7)|.*3
6
9
12
15
18
jq> [range(2;7)|.*3]
[
  6,
  9,
  12,
  15,
  18
]
jq>
```

</details>


rsrelease
-------------------------------------------------------------------------------
Quick release of Rust packaging

<details>
<summary>Show Code</summary>

```
$ rsrelease -h
===> 'hash' 'cargo' 'jq'
Usage: rsrelease [Options]

Options:
    -t <target>        set target
    -H <hasher>        set hasher
    -n <name>          set bin name
    -h                 show help
$ rsrelease
===> 'hash' 'cargo' 'jq'
===> 'hash' 'sha256sum'
===> 'cargo' 'build' '--release' '--target=aarch64-unknown-linux-musl'
    Finished `release` profile [optimized] target(s) in 0.06s
===> 'test' '-d' 'target/aarch64-unknown-linux-musl/'
===> 'cd' 'target/aarch64-unknown-linux-musl//release/'
===> 'test' '-f' 'test_'
===> 'test' '-r' 'test_'
===> 'test' '-x' 'test_'
===> 'rm' 'test__v0.1.0_aarch64-unknown-linux-musl.tar.xz'
===> 'tar' '-cf' 'test__v0.1.0_aarch64-unknown-linux-musl.tar' 'test_'
===> 'xz' '-9evvT1' 'test__v0.1.0_aarch64-unknown-linux-musl.tar'
xz: Filter chain: --lzma2=dict=64MiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=512
xz: 674 MiB of memory is required. The limiter is disabled.
xz: Decompression will need 65 MiB of memory.
test__v0.1.0_aarch64-unknown-linux-musl.tar (1/1)
  100 %       148.5 KiB / 390.0 KiB = 0.381
===> 'sha256sum' 'test__v0.1.0_aarch64-unknown-linux-musl.tar.xz'
===> 'echo' '493cdec1666c7f0bab84c4a24f65b92afecea8b01165bd670ae91cdf4668f751  test__v0.1.0_aarch64-unknown-linux-musl
.tar.xz'
$ ls target/aarch64-unknown-linux-musl/release/
build  examples     test_    test__v0.1.0_aarch64-unknown-linux-musl.tar.xz
deps   incremental  test_.d  test__v0.1.0_aarch64-unknown-linux-musl.tar.xz.sha256sum
```

</details>
