# Git 指令完整參考手冊

> 涵蓋設定、基本操作、分支管理、遠端協作、復原修正、進階工具等所有常用指令與其選項

---

## 目錄

1. [設定與初始化](#1-設定與初始化)
2. [取得與建立專案](#2-取得與建立專案)
3. [基本操作(新增、修改、提交)](#3-基本操作新增修改提交)
4. [查看歷史與差異](#4-查看歷史與差異)
5. [分支管理](#5-分支管理)
6. [合併與重定基底](#6-合併與重定基底)
7. [遠端協作](#7-遠端協作)
8. [暫存區(Stash)](#8-暫存區stash)
9. [標籤(Tag)](#9-標籤tag)
10. [復原與修正](#10-復原與修正)
11. [檔案管理](#11-檔案管理)
12. [子模組(Submodule)](#12-子模組submodule)
13. [工作樹(Worktree)](#13-工作樹worktree)
14. [除錯與進階工具](#14-除錯與進階工具)
15. [常用設定技巧](#15-常用設定技巧)

---

## 1. 設定與初始化

### `git init`
建立一個新的 Git 倉庫。

```bash
git init                  # 在當前目錄建立倉庫
git init <目錄名>          # 在指定目錄建立倉庫
git init --bare           # 建立純倉庫(無工作目錄,常用於伺服器端)
```

### `git config`
設定使用者資訊與行為。

```bash
git config --global user.name "你的名字"
git config --global user.email "you@example.com"
git config --global core.editor "vim"          # 設定預設編輯器
git config --global init.defaultBranch main      # 設定預設分支名稱
git config --list                                # 列出所有設定
git config --list --show-origin                  # 顯示設定來自哪個檔案
git config <key>                                  # 查看單一設定值
git config --global --unset <key>                # 移除設定
git config --local user.name "專案專用名稱"        # 只套用於目前倉庫
```

常用選項:
| 選項 | 說明 |
|---|---|
| `--global` | 套用於目前使用者所有倉庫(存於 `~/.gitconfig`) |
| `--local` | 只套用於目前倉庫(預設,存於 `.git/config`) |
| `--system` | 套用於整台機器所有使用者 |

---

## 2. 取得與建立專案

### `git clone`
複製遠端倉庫到本地。

```bash
git clone <url>                       # 複製倉庫
git clone <url> <目錄名>               # 複製並指定資料夾名稱
git clone --depth 1 <url>             # 淺複製,只抓最新一次提交(加快速度)
git clone -b <分支名> <url>            # 複製時直接切換到指定分支
git clone --recurse-submodules <url>  # 同時複製子模組
```

---

## 3. 基本操作(新增、修改、提交)

### `git status`
查看目前工作目錄與暫存區狀態。

```bash
git status
git status -s          # 簡短格式輸出
git status -b          # 顯示分支資訊
```

### `git add`
將變更加入暫存區(staging area)。

```bash
git add <檔案>          # 加入指定檔案
git add .               # 加入目前目錄所有變更
git add -A              # 加入所有變更(含刪除、新增、修改)
git add -p              # 互動式選擇要加入的片段(patch 模式)
git add -u               # 只加入已追蹤檔案的修改(不含新檔案)
```

### `git commit`
提交暫存區的變更。

```bash
git commit -m "訊息"            # 提交並附上訊息
git commit -am "訊息"           # 等同 git add -u + commit(只對已追蹤檔案)
git commit --amend              # 修改最後一次提交(訊息或內容)
git commit --amend --no-edit    # 修改內容但不改訊息
git commit -v                   # 提交時顯示 diff 內容
git commit --allow-empty -m "" # 允許建立空提交
```

### `git diff`
查看尚未提交的變更內容。

```bash
git diff                        # 工作目錄 vs 暫存區
git diff --staged               # 暫存區 vs 上一次提交(等同 --cached)
git diff HEAD                   # 工作目錄 vs 上一次提交
git diff <commit1> <commit2>    # 比較兩個提交
git diff <branch1> <branch2>    # 比較兩個分支
git diff -- <檔案>               # 只看特定檔案差異
git diff --stat                 # 只顯示變更統計(增減行數)
```

---

## 4. 查看歷史與差異

### `git log`
查看提交歷史。

```bash
git log                          # 完整歷史
git log --oneline                # 每筆提交一行
git log --oneline --graph --all  # 圖形化顯示所有分支歷史
git log -p                       # 顯示每次提交的差異內容
git log -n 5                     # 只看最近 5 筆
git log --author="名字"           # 篩選特定作者
git log --since="2 weeks ago"    # 篩選時間範圍
git log --grep="關鍵字"           # 依提交訊息搜尋
git log -- <檔案>                 # 查看特定檔案的歷史
git log --follow -- <檔案>        # 追蹤檔案改名前的歷史
```

### `git show`
顯示指定提交的詳細內容。

```bash
git show <commit-hash>
git show HEAD            # 顯示最新提交
git show HEAD~2          # 顯示前兩個提交
```

### `git blame`
查看每一行程式碼是誰、何時修改的。

```bash
git blame <檔案>
git blame -L 10,20 <檔案>   # 只看第 10~20 行
```

### `git shortlog`
彙整提交歷史,常用於統計貢獻者。

```bash
git shortlog -sn       # 依提交數排序列出每個作者
```

---

## 5. 分支管理

### `git branch`
建立、列出、刪除分支。

```bash
git branch                    # 列出本地分支
git branch -a                 # 列出所有分支(含遠端)
git branch -r                 # 只列出遠端分支
git branch <名稱>              # 建立新分支
git branch -d <名稱>           # 刪除已合併的分支
git branch -D <名稱>           # 強制刪除分支(未合併也刪)
git branch -m <舊名> <新名>     # 重新命名分支
git branch -v                 # 顯示分支最新提交資訊
git branch --merged           # 列出已合併到目前分支的分支
git branch --no-merged        # 列出尚未合併的分支
```

### `git switch`(新版建議用法)
切換分支。

```bash
git switch <分支名>             # 切換到已存在的分支
git switch -c <新分支名>         # 建立並切換到新分支
git switch -c <新分支名> <起點>   # 從指定提交/分支建立新分支
git switch -                   # 切換回上一個分支
```

### `git checkout`(傳統用法,功能較多但較易混淆)

```bash
git checkout <分支名>            # 切換分支
git checkout -b <新分支名>        # 建立並切換新分支
git checkout <commit-hash>      # 切換到指定提交(detached HEAD 狀態)
git checkout -- <檔案>           # 放棄該檔案的未提交修改
```

---

## 6. 合併與重定基底

### `git merge`
合併分支。

```bash
git merge <分支名>              # 將指定分支合併進目前分支
git merge --no-ff <分支名>      # 強制建立合併提交(即使可以快進)
git merge --abort               # 取消合併(發生衝突時)
git merge --squash <分支名>     # 將對方分支所有提交壓成一筆變更(不自動提交)
```

### `git rebase`
重新接上提交歷史,讓歷史更線性。

```bash
git rebase <分支名>             # 將目前分支重定基底到指定分支
git rebase -i <commit-hash>     # 互動式重定基底(可調整、合併、刪除提交)
git rebase --continue           # 解決衝突後繼續
git rebase --abort              # 取消整個 rebase
git rebase --skip               # 跳過目前衝突的提交
git rebase --onto <新基底> <舊基底> <分支>   # 進階:轉移一段提交到新基底
```

互動式 rebase(`-i`)中可用指令:
| 指令 | 說明 |
|---|---|
| `pick` | 保留此提交 |
| `reword` | 保留內容但修改訊息 |
| `edit` | 暫停讓你修改此提交內容 |
| `squash` | 與前一筆提交合併,並合併訊息 |
| `fixup` | 與前一筆提交合併,丟棄此筆訊息 |
| `drop` | 刪除此提交 |

### `git cherry-pick`
挑選特定提交套用到目前分支。

```bash
git cherry-pick <commit-hash>
git cherry-pick <hash1> <hash2>     # 挑選多個提交
git cherry-pick --continue          # 解決衝突後繼續
git cherry-pick --abort             # 取消
git cherry-pick -n <commit-hash>    # 套用變更但不自動提交
```

---

## 7. 遠端協作

### `git remote`
管理遠端倉庫連結。

```bash
git remote -v                          # 列出遠端倉庫(含網址)
git remote add <名稱> <url>             # 新增遠端倉庫
git remote remove <名稱>                # 移除遠端倉庫
git remote rename <舊名> <新名>          # 重新命名
git remote set-url <名稱> <新url>        # 修改遠端網址
git remote show <名稱>                  # 顯示遠端詳細資訊
```

### `git fetch`
從遠端抓取資料,但不自動合併。

```bash
git fetch <遠端名>            # 抓取指定遠端
git fetch --all              # 抓取所有遠端
git fetch --prune            # 同時清除遠端已刪除的分支追蹤
```

### `git pull`
抓取並合併(= fetch + merge,或 fetch + rebase)。

```bash
git pull                       # 抓取並合併目前分支對應的遠端分支
git pull --rebase              # 用 rebase 而非 merge 的方式整合
git pull <遠端名> <分支名>       # 指定遠端與分支
```

### `git push`
將本地提交推送到遠端。

```bash
git push                              # 推送到目前分支對應的遠端
git push <遠端名> <分支名>             # 推送指定分支
git push -u origin <分支名>            # 推送並設定追蹤關係(之後可單純用 git push)
git push --force                      # 強制推送(覆蓋遠端歷史,危險)
git push --force-with-lease           # 較安全的強制推送(若遠端有新提交會拒絕)
git push --tags                       # 推送所有標籤
git push origin --delete <分支名>      # 刪除遠端分支
```

---

## 8. 暫存區(Stash)

暫時保存尚未提交的修改,稍後再取回。

```bash
git stash                       # 暫存目前所有變更
git stash save "說明文字"        # 暫存並附上說明
git stash -u                    # 連同未追蹤的新檔案一起暫存
git stash list                  # 列出所有暫存
git stash show -p stash@{0}     # 查看暫存內容差異
git stash pop                   # 取出最新暫存並刪除該紀錄
git stash apply                 # 取出最新暫存但保留紀錄
git stash apply stash@{2}       # 取出指定編號的暫存
git stash drop stash@{0}        # 刪除指定暫存紀錄
git stash clear                 # 清空所有暫存
git stash branch <新分支名>      # 用暫存內容建立新分支
```

---

## 9. 標籤(Tag)

用於標記版本(如 v1.0.0)。

```bash
git tag                          # 列出所有標籤
git tag <標籤名>                  # 建立輕量標籤(指向目前提交)
git tag -a <標籤名> -m "說明"      # 建立含說明的附註標籤
git tag <標籤名> <commit-hash>    # 對指定提交打標籤
git tag -d <標籤名>                # 刪除標籤
git show <標籤名>                  # 查看標籤資訊
git push origin <標籤名>           # 推送單一標籤
git push origin --tags            # 推送所有標籤
git push origin --delete <標籤名>  # 刪除遠端標籤
```

---

## 10. 復原與修正

### `git reset`
移動 HEAD 與分支指向,可選擇是否影響暫存區/工作目錄。

```bash
git reset <檔案>                  # 將檔案從暫存區移出(不影響工作目錄內容)
git reset --soft <commit>        # 移動 HEAD,保留暫存區與工作目錄變更
git reset --mixed <commit>       # (預設)移動 HEAD,清空暫存區,保留工作目錄
git reset --hard <commit>        # 移動 HEAD,清空暫存區與工作目錄(危險,會丟失修改)
git reset HEAD~1                 # 回到上一個提交(保留變更內容)
```

### `git revert`
建立一個新提交來「抵銷」某次提交的內容(安全,不改寫歷史)。

```bash
git revert <commit-hash>          # 反轉指定提交
git revert -n <commit-hash>       # 反轉但不自動提交,可繼續編輯
git revert --abort                # 取消 revert
```

### `git reflog`
查看 HEAD 移動的完整紀錄,可用來救回「遺失」的提交。

```bash
git reflog
git reset --hard HEAD@{2}    # 回到 reflog 中記錄的某個狀態
```

---

## 11. 檔案管理

### `git rm`
刪除檔案並記錄到 Git。

```bash
git rm <檔案>                 # 刪除檔案(工作目錄與暫存區皆刪)
git rm --cached <檔案>         # 只從 Git 追蹤中移除,保留實體檔案
git rm -r <資料夾>             # 遞迴刪除整個資料夾
```

### `git mv`
重新命名或移動檔案。

```bash
git mv <舊檔名> <新檔名>
```

### `git clean`
清除未被追蹤的檔案。

```bash
git clean -n          # 預覽會被刪除的檔案(不實際刪除)
git clean -f           # 刪除未追蹤的檔案
git clean -fd          # 同時刪除未追蹤的資料夾
git clean -fx          # 連 .gitignore 忽略的檔案也一起刪除
```

---

## 12. 子模組(Submodule)

在一個 Git 倉庫中包含另一個獨立的 Git 倉庫。

```bash
git submodule add <url> <路徑>         # 新增子模組
git submodule init                     # 初始化子模組設定
git submodule update                   # 依紀錄更新子模組內容
git submodule update --init --recursive  # 初始化並更新所有(含巢狀)子模組
git submodule status                   # 查看子模組狀態
git submodule deinit <路徑>             # 移除子模組設定
git submodule foreach 'git pull'       # 對所有子模組執行指令
```

---

## 13. 工作樹(Worktree)

讓同一個倉庫可以同時在多個資料夾、多個分支下工作。

```bash
git worktree add <路徑> <分支名>      # 在新路徑建立指定分支的工作樹
git worktree add -b <新分支> <路徑>   # 建立新分支並同時建立工作樹
git worktree list                    # 列出所有工作樹
git worktree remove <路徑>            # 移除工作樹
```

---

## 14. 除錯與進階工具

### `git bisect`
用二分搜尋法找出哪個提交引入了 bug。

```bash
git bisect start
git bisect bad                  # 標記目前版本為有問題
git bisect good <commit-hash>   # 標記某個提交為正常
# Git 會自動切換到中間的提交,重複測試並標記 good/bad
git bisect reset                # 結束並回到原本分支
```

### `git fsck`
檢查倉庫物件完整性。

```bash
git fsck                  # 檢查並列出問題物件
git fsck --full            # 完整檢查
```

### `git gc`
清理並最佳化倉庫(壓縮物件、移除無用資料)。

```bash
git gc                  # 一般清理
git gc --aggressive      # 更徹底但較耗時的清理
```

### `git archive`
將指定版本的內容打包匯出(不含 .git 資料夾)。

```bash
git archive --format=zip HEAD -o 專案快照.zip
```

### `git rev-parse`
解析各種引用(分支、HEAD 等)為實際的 commit hash,常用於腳本。

```bash
git rev-parse HEAD
git rev-parse --abbrev-ref HEAD    # 顯示目前分支名稱
```

---

## 15. 常用設定技巧

### 建立指令別名

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm "commit -m"
git config --global alias.lg "log --oneline --graph --all"
```
之後即可用 `git st`、`git lg` 等簡寫指令。

### `.gitignore`
在專案根目錄建立 `.gitignore` 檔案,列出要忽略的檔案/資料夾(每行一個規則),例如:

```
node_modules/
*.log
.env
.DS_Store
```

### 常見工作流程範例

**日常開發流程:**
```bash
git checkout -b feature/新功能      # 建立功能分支
# ...修改程式碼...
git add .
git commit -m "新增功能說明"
git push -u origin feature/新功能
# 在 GitHub 上開 Pull Request
```

**同步遠端最新變更並避免額外合併提交:**
```bash
git pull --rebase origin main
```

**修正剛剛打錯的提交訊息:**
```bash
git commit --amend -m "正確的訊息"
```

**不小心 commit 到錯的分支,想搬到新分支:**
```bash
git branch 新分支名         # 在目前位置建立新分支(帶走剛剛的提交)
git reset --hard HEAD~1     # 把原分支退回去
git switch 新分支名          # 切到新分支繼續
```

---

> 提示:大多數指令都可以加 `-h` 查看該指令的說明,例如 `git commit -h`、`git rebase -h`。
