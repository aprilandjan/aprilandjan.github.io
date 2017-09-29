---
layout: post
title:  git operations
date:   2017-04-24 10:51:00 +0800
categories: git
---

这篇文章用来记录工作中经常要用到的一些 git 操作。

## git(全局)设置

- 查看全局设置：
  
  ```bash
  git config --global --list
  ```

- 修改全局设置:

  ```bash
  git config --global user.name your_new_name
  git config --global user.email your_new_email
  ```

## 删除远端分支

```
git push -d origin <branch-name>
```

## 更改远端仓库地址

参考 [Github Help](https://help.github.com/articles/changing-a-remote-s-url/):

```
git remote set-url <remote_name> <remote_address>
```


## 重命名上一次尚未提交到远端的 commit

参考[https://stackoverflow.com/questions/179123/how-to-modify-existing-unpushed-commits](https://stackoverflow.com/questions/179123/how-to-modify-existing-unpushed-commits):

```bash
git commit --amend -m <commit_message>
```

## 重置指定文件至某个 commit

```bash
gut checkout <commit_id> <file_path>
```

## 重置本地代码库至某个 commit

```bash
git reset --hard <commit_id>
git reset --soft HEAD@{1}
git commit -m 'revert to ...'
```

## 清理本地仓库，删除多余的(未追踪的, 但不是被忽略的)文件

```bash
git clean -d -f
```

参考 [git-scm](https://git-scm.com/docs/git-clean), `git clean` 会提示删掉所有未追踪的文件，但是不包括文件夹。`-d`参数也会删除未追踪的文件夹, 而 `-f` 参数不添加的话可能默认只是提示有哪些文件可以被删除而不是真正的删除。

## 同一台机器多个 github 帐号 ssh 管理

可以在用户目录(`~`)下添加配置文件 `.ssh/config` 的方式实现：

```
Host  github.com
  HostName  github.com
  User aprilandjan
  IdentityFile  ~/.ssh/id_rsa_github
Host  coding.net
  HostName coding.net
  User aprilandjan
  IdentityFile ~/.ssh/id_rsa_coding
```

## 重置到某个 commit 并保留文件改动

```bash
git reset <commit/sha/tag>
```

例如，想回退到上个 commit 并且保留文件的改动，可以执行 `git reset HEAD^`, 其中 `HEAD^` 代表当前 commit 的上一个 commit.

## 利用 `stash` 在不同分支上转移修改

首先要保证想转移的修改处于 unstage 状态，例如通过 `git reset HEAD^`把某分支回退到提交前的状态；这个时候可以使用 `stash` 转移修改：

```bash
git stash
git checkout <branch-name>
git stash pop
```

## 清理文件夹下的 svn 控制信息

参考 [http://stackoverflow.com/questions/154853/how-do-you-remove-subversion-control-for-a-folder](http://stackoverflow.com/questions/154853/how-do-you-remove-subversion-control-for-a-folder):

```bash
find . -iname ".svn" -print0 | xargs -0 rm -r
```

##  从仓库内的所有 commit 彻底删除某文件

如果某个仓库不慎把一些含有敏感信息的文件提交了，此时可能需要在每一个 commit 节点上都彻底删除该文件，否则即便删除了 head 下的文件再提交，历史 commit 里仍然也是能看到。所幸 git 提供了这样的功能，参考 [stackoverflow](https://stackoverflow.com/questions/307828/completely-remove-file-from-all-git-repository-commit-history) [github help]():

```bash
git filter-branch --index-filter 'git rm --cached --ignore-unmatch <file>'

git push origin --all --force
```

这个方式会更改到所有涉及到的 commit 节点，最后再通过 `push --force` 覆盖到远端，因此参与项目的其他人可能需要重新 `clone` 一次代码了... 