---
layout: post
title:  isolate git branch
date:   2017-01-05 23:47:00 +0800
categories: mac
---

公司不给一些零散的项目开单独的 git 仓库, 这些零散的项目往往放在一个仓库里。如果把这些项目都集中放在一起, 感觉不利于区分的同时, 久而久之目录也就会越来越大, 所以目前的做法是把这些项目分散在同一个仓库里的不同分支里。
这样也有一定的问题, 如果都是在同一个目录下开发, 平常可能需要处理多个分支的项目的时候, 会需要来回切换分支, 切来切去可能当前工作区域就不太方便保存了。
另外, 前端项目的 node_modules 因为是被忽略掉不进入版本库的, 所以实际上多个分支都在共用同一个 node_modules 目录, 而不同项目需求的某个模块版本很可能是不一样的, 结果有可能会造成引入错误的模块版本 —— npm 到目前位置似乎仍然没有一个在同一个目录下引入同一模块的不同版本的切实有效的方法, yarn 也没有。

看来, 虽然是可以共用同一个仓库, 但是最好还是得在本地路径里彼此独立。以下是一种操作方式:

```bash
mkdir my-new-branch
cd my-new-branch
git init
git add -A
git commit -m 'init-branch'
git checkout -b my-new-branch
git remote add origin git@remotereposity
git push -u origin my-new-branch
```

这样便让新建的项目目录与远端仓库的新建分支联系起来了, 以后开发该项目, 就在这个新建目录里开发即可。