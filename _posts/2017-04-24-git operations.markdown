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

## 同一台机器多个 github 帐号 ssh 管理

## 重置到某个 commit 并保留文件改动

```bash
git reset 56e05fced
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