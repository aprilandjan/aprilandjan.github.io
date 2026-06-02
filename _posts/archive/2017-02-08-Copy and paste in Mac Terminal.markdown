---
layout: post
title:  Copy and paste in Mac Terminal
date:   2017-02-08 15:02:00 +0800
categories: linux
---

有的时候需要在不同项目目录之间拷贝文件，每次都要打开两个目录，操作略显繁琐。网上搜了一下，在 mac terminal 中也是可以复制粘贴的。

### Copy

```bash
cat path/to/target/file.ext | pbcopy
``` 

### Paste

```bash
pbpaste > path/to/paste/target/file.ext
```
### Tips

经测试，发现这种复制粘贴的方法无法与 `Command+C` `Command+V` 混用，而且也只是在 mac terminal 中可用。