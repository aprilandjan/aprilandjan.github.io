---
layout: post
title:  git operations
date:   2017-04-24 10:51:00 +0800
categories: git
---

这篇文章用来记录工作中经常要用到的一些 git 操作。

## 重置本地代码库至某个 commit

```bash
git revert --hard 56e05fced
git reset --soft HEAD@{1}
git commit -m 'revert to 56e05fced'
```

## 同一台机器多个 github 帐号 ssh 管理

## 利用 `stash` 在不同分支上转移修改
