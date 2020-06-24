---
layout: post
title:  Process Signal in node.js
link: process-signal-in-nodejs
date:   2020-01-20 10:50:00 +0800
categories: nodejs
---

通过 `nodejs` 运行代码时，通常如果事件循环队列中没有更多的可能可执行的任务了，程序会自动的退出。例如：

```js
// add.js
var a = 1;
var b = 2;
console.log(a + b);
```

在控制台中输入命令 `node ./add.js` 执行后，可以发现程序在打印出数字 `3` 之后即自动退出，不会影响在当前控制台窗口继续去执行其他的命令或运行程序。但有时运行某些代码，例如启动服务监听、执行定时器、触发异步操作、监听 stdin 等等，例如：

```js
// keep-alive.js
process.stdin.resume();
setInterval(() => {}, 10000);
```

这种不会自动退出的 `nodejs` 程序在运行时，进程(`process`) 会保持存在(`keep-alive`)；当需要对它进行消息通知等控制时，需要采用特定的方式方法去触发执行。

最常见的情况是，我们可能想立刻结束掉该进程，以便释放该进程占用的资源，或恢复当前命令行窗口的可用性。在这个程序正在执行的命令行窗口中，键入 <kbd>Ctrl</kbd>+<kbd>C</kbd> 往往可以立刻结束该进程。为什么键入该组合按键就能中止进程，这背后存在什么样的逻辑？

## Signal

## `process.kill`

## `process.exit`

## `process.on`

## 子进程

## References

- <https://hackernoon.com/graceful-shutdown-in-nodejs-2f8f59d1c357>
- <https://nodejs.org/api/process.html#process_signal_events>
- <https://stackoverflow.com/questions/14031763/doing-a-cleanup-action-just-before-node-js-exits/14032965#14032965>
