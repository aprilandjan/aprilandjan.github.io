---
layout: post
title:  Process Signal in node.js
link: process-signal-in-nodejs
date:   2020-01-20 10:50:00 +0800
categories: nodejs
---

使用 `nodejs` 运行代码时，通常如果事件循环队列中没有更多的可能可执行的任务了，程序会自动的退出。例如：

```js
// add.js
var a = 1;
var b = 2;
console.log(a + b);
```

在控制台中输入命令 `node ./add.js` 执行后，可以发现程序在打印出数字 `3` 之后即自动退出，不会影响在当前控制台窗口继续去执行其他的命令或运行程序。但有时运行诸如启动服务监听、执行定时器、触发异步操作、监听 stdin 等等操作时，例如：

```js
// keep-alive.js
process.stdin.resume();
setInterval(() => {}, 10000);
```

进程(`process`) 会保持存活状态(`keep-alive`)，不会自动退出。当需要对该进程进行消息通知等控制时，也需要采用特定的方式方法去触发执行。

最常见的情况是，我们可能想立刻结束掉该进程，以便释放该进程占用的资源，或恢复当前命令行窗口的可用性。通常，在该命令行窗口中，键入 <kbd>Ctrl</kbd>+<kbd>C</kbd> 可以立刻结束该进程。那为什么键入该组合按键就能中止进程，这背后发生了怎样的逻辑？要了解这些，我们首先需要知道进程及信号之间的关系。

## Signal

在 `*nix` 中，Signal（信号）是一种由操作系统或者某些程序发送给特定进程的通知消息。该通知通常是单向的、异步响应的，可以由其他进程发给指定进程，也可以由某进程发给自己。Signal 通常都指代了特定的行为命令，例如程序出错，或者是用户键入了 <kbd>Ctrl</kbd>+<kbd>C</kbd>。每一种信号都有一个对应的数字 ID。在 Linux 系统中定义了三十多种有信号。以下是一些常见的信号及其含义：

|Signal|No|Linux 说明|
|---|---|---|
|SIGHUP|1|Hang Up. 如果进程从命令行启动，但命令行消失，则程序收到该信号。在 `nodejs` 中，windows 环境下程序会自动的在约10秒后无条件退出；在 mac 环境下如果没有用户针对该信号定义的行为，会默认立即退出|
|SIGINT|2|Interrupted. 从命令行启动的进程被中断，通常是用户键入了 <kbd>Ctrl</kbd>+<kbd>C</kbd>。在 `nodejs` 中，如果没有对该信号的自定义监听，会默认立刻退出|
|SIGKILL|9|Kill. 进程被其他程序显式的终止，例如调用了 `kill` 程序去结束该进程。在 `nodejs` 中，该信号会使当前进程无条件的立即中止，无论是 mac 还是 windows 系统，且无法定义自定义信号监听回调|
|SIGUSR1|10|用户自定义的响应信号的行为。在 `nodejs` 中，该信号默认被用来启动 `nodejs` 的调试模式|
|SIGTERM|15|Terminate. 同 `SIGKILL`，进程被其他程序显式的终止，例如调用了 `kill` 程序去结束该进程。在 `nodejs` 中，windows 环境下没有对该信号的处理，可以由用户自定义监听|
|SIGSTOP|19|由操作系统发出，保存其状态并停止运行；程序将不会获得更多的 CPU 时钟|

注：windows 系统并不支持信号，而是有自己的一套进程间消息通知机制，因此对于一个 `nodejs` 程序，也没有通过信号去中止程序的方法。但是 `nodejs` 通过 `process.kill()` 及 `subprocess.kill()` 提供了一定的模拟实现，可以发送 `SIGINT` `SIGTERM` 或 `SIGKILL` 到某个进程。

## `process.on`

通过上表可以看到，有多种信号 `SIGIUP` `SIGINT` `SIGKILL` `SIGTERM` 等能使进程中止。那么在 `nodejs` 中要如何监听这些信号事件呢？

可以通过 `process.on` 添加对这些信号的事件监听以自定义某些行为，例如：

```js
// Begin reading from stdin so the process does not exit.
process.stdin.resume();

// listen SIGINT
process.on('SIGINT', () => {
  console.log('receive SIGINT');
});
```

当启动该程序后，键入 <kbd>Ctrl</kbd>+<kbd>C</kbd> 时程序不会自动中止，而是打印出信息，说明信号被正确的监听并响应，且阻止了默认的中止行为：

```bash
^Creceive SIGINT
```

此时要中止掉该进程，可以在另外的控制台窗口使用 Linux 系统自带的 [`kill`](https://ss64.com/osx/kill.html) 命令；默认情况下，该命令会发送 `SIGTERM` 信号：

```bash
kill <pid>
```

另外，我们也可以通过 `kill` 命令给指定进程发送特定的信号，例如，尝试对以上的 `nodejs` 进程发送 `SIGUSR1` 信号：

```bash
kill -SIGUSR1 <pid>
```

可以看到，该程序控制台打印出了调试模式开启的说明：

```bash
Debugger listening on ws://127.0.0.1:9229/2030c055-5018-453d-a840-18f21ead1e8c
For help, see: https://nodejs.org/en/docs/inspector
```

注：在 unix 系统中，进程对 `SIGKILL` 的响应和中止总是可以保障的，因此，无论程序做了怎样的处理，通过 `kill -9 <pid>` 总是能中止进程（[参考](https://unix.stackexchange.com/questions/5642/what-if-kill-9-does-not-work))；`nodejs` 对 `SIGKILL` 信号的监听响应总是无条件的、无法通过用户自定义行为覆盖的，尝试监听该信号会生成一个运行时的错误。

## `process.kill`

与系统自带的 `kill` 命令相似，在 `nodejs` 中可以使用 [`process.kill`](https://nodejs.org/api/process.html#process_process_kill_pid_signal) 给指定 `pid` 的进程发送信号。需要注意的是：

1. 该方法虽然名称是 `kill`，但并不是中止进程，而是只发送信号；
2. 必须指定 `pid`；如果想对自身发送信号，可以使用 `process.kill(process.pid)`；
3. 对于 `nodejs` 中通过 `spawn` 等方法得到子进程实例，也拥有 `kill` 方法，可以通过它直接发送信号，例如：

    ```js
    const spawn = require('child_process').spawn;
    const grep = spawn('grep', ['ssh']);

    grep.on('close', (code, signal) => {
      console.log(
        `child process terminated due to receipt of signal ${signal}`);
    });

    //  the following two methods are the same
    grep.kill('SIGINT')
    // process.kill(grep.pid, 'SIGINT');
    ```

## `process.exit`

除了发送信号中止进程，`nodejs` 中也可以通过 [`process.exit(exitCode)`](https://nodejs.org/api/process.html#process_process_exit_code) 方法退出进程：

```js
process.stdout.resume();

console.log(process.pid);

function handler (signal) {
  console.log('receive', signal);
}

process.on('SIGHUP', handler);
process.on('SIGINT', handler);
process.on('SIGTERM', handler);

process.exit(1);
```

在上例中，即便我们通过自定义对 `SIGHUP` `SIGINT` `SIGTERM` 等中止信号的监听，阻止了 `nodejs` 默认的信号响应行为，但通过 `process.exit(1)` 也依然成功的退出了当前进程。此外：

1. 通过参数 `exitCode` 可以用退出状态码来标识程序运行结果是成功还是失败；
2. 通过对进程监听事件 `process.on('exit', callback)` 可以添加程序退出前需要执行的 **同步回调** 事件；回调中的任何异步操作例如定时器、fs、iostream 等，都会在同步调用结束后丢弃；
3. 在所有的 `exit` 事件回调都调用之后，程序会立刻退出。

## Parent & Child Processes

假设现在通过 `spawn` 方法调用起若干子进程各自执行任务，父子进程之间往往希望形成一个组，当其中任意一个进程因故退出时，其他的进程也都中止。情况如下：

1. 父进程异常中止，此时要结束子进程；
2. 某一子进程异常中止，此时要结束其他子进程以及父进程。

## References

- <https://hackernoon.com/graceful-shutdown-in-nodejs-2f8f59d1c357>
- <https://nodejs.org/api/process.html#process_signal_events>
- <https://stackoverflow.com/questions/14031763/doing-a-cleanup-action-just-before-node-js-exits/14032965#14032965>
- <https://www-uxsup.csx.cam.ac.uk/courses/moved.Building/signals.pdf>
- <https://www.bogotobogo.com/Linux/linux_process_and_signals.php>
- <https://man7.org/linux/man-pages/man7/signal.7.html>
- <https://github.com/sindresorhus/exit-hook>
- <https://github.com/tapppi/async-exit-hook>
- <https://ss64.com/osx/kill.html>
