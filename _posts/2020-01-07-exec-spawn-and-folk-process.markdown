---
layout: post
title:  exec, spawn and folk process in nodejs
link:   exec-spawn-and-folk-process-in-nodejs
date:   2020-01-07 22:58:00 +0800
categories: node
---

在 `node.js` 中，可以通过内置的模块 `child_process` 启动子进程执行程序。例如：

```javascript
const { spawnSync, execSync } = require('child_process');

const cmd = 'echo 123';

//  exec
execSync(cmd);

//  spawn
spawnSync(cmd);
```

从执行的结果看，`exec` 和 `spawn` 都可以执行指定的命令。那么这两个方法的差异点在哪里？
