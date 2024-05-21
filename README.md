**LICENSE**: MIT

Some personal bash scripts that may be useful.


some simple sample
-------------------------------------------------------------------------------
**short-git**

<details>
<summary><font size="4" color="orange">Show Code</font></summary>

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
branch commands:
    s       switch
    r       rebase
    i       rebase -i
    m       merge
    M       merge --no-ff
    L       log --oneline --graph
    D       branch -d
    ^P      push <origin>
short-git> u
1) origin
select orig (git remote update)> 1
==> remote update origin
Fetching origin
short-git> l
==> log --oneline --graph --all
* db35ae5 (HEAD -> main, origin/main) Add git show for short-git.sh
* ccb2871 add short-git.sh
* 9c03f41 Create README.md
* 29e28cf Initial commit
short-git> s
1) main
select ref (git switch)> 1
==> switch main
Already on 'main'
Your branch is up to date with 'origin/main'.
short-git> S
==> show
commit db35ae5b187ba8e20fa6a5df186a8ee06be3aed9 (HEAD -> main, origin/main)
Author: A4-Tacks <wdsjxhno1001@163.com>
Date:   Tue May 21 23:43:31 2024 +0800

    Add git show for short-git.sh

diff --git a/short-git.sh b/short-git.sh
index a5481e0..6cf99cc 100644
--- a/short-git.sh
+++ b/short-git.sh
@@ -44,14 +44,15 @@ function short-git {
                 cat <<- EOF
                                short-git
                                simple commands:
-                                   h / ?   show this help
-                                   H       show git help
+                                   h / ?   :show this help
+                                   H       :show git help
                                    q / ^D  quit
                                    ^M      status
                                    d       diff
                                    l       log --oneline --graph --all
                                    p       push
                                    u       remote update
+                                   S       show
                                branch commands:
                                    s       switch
                                    r       rebase
@@ -69,6 +70,7 @@ function short-git {
             d) git diff;;
             l) git log --oneline --graph --all;;
             p) git push;;
+            S) git show;;

             $'\020') cmd_args=(push);;&
             u) cmd_args=(remote update);;&
short-git> q
```

</details>
