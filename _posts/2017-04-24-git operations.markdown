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

## 更改远端仓库地址

## 重置本地代码库至某个 commit

```bash
git reset --hard 56e05fced
git reset --soft HEAD@{1}
git commit -m 'revert to 56e05fced'
```

## 同一台机器多个 github 帐号 ssh 管理

## 利用 `stash` 在不同分支上转移修改
