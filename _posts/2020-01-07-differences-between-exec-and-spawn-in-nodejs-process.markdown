---
layout: post
title:  nodejs 中 exec 与 spawn 的差异点
link: differences-between-exec-and-spawn-in-nodejs-process
date:   2020-01-07 22:58:00 +0800
categories: os nodejs
---

在 `node.js` 中，可以通过内置的模块 `child_process` 启动子进程执行程序。例如：

```javascript
const { exec, spawn } = require('child_process');

//  exec
exec('echo google.com');

//  spawn
spawn('echo', ['google.com']);
```

从执行的结果看，`exec` 和 `spawn` 都可以执行指定的命令。那么这两个方法的差异点在哪里？

## 参数

首先是他们的使用时参数不一样:

- [exec(command)](https://nodejs.org/api/child_process.html#child_process_child_process_exec_command_options_callback) 的参数 `command` 可以以字符串的形式拼接参数，因此可以像平常在 `bash` 中敲命令一般输入完整带参的命令内容，例如 `echo google.com`；
- [spawn(command, args?)](https://nodejs.org/api/child_process.html#child_process_child_process_spawn_command_args_options) 的参数中区分了命令 `command` 以及针对该命令附加的参数列表 `args?`。因此必须分别定义传递，例如 `spawn('echo', ['google.com'])`。

## 输出使用

其次，他们对被执行的命令的输出结果的使用方式也不一样：

- `exec()` 通常应配合着其回调参数使用。例如：

  ```javascript
  exec('echo google.com', (error, stdout, stderr) => {
    if (error) {
      console.error(error);
    }
    console.log('stdout', stdout);
    console.error('stderr', stderr);
  })
  ```

  这是一种典型的 node.js 式的回调。可以使用 `utils.promisify` 将其转换为基于 promise 的形式：

  ```javascript
  const exec = utils.promisify(require('child_process').exec);
  exec('echo google.com').then(({ stdout, stderr }) => {
    console.log('stdout', stdout);
    console.error('stderr', stderr);
  });
  ```

  可以注意到，在回调结果里通过 `stdout` `stderr` 拿到的始终是这个**命令尽可能完成执行**之后所产生的全部 `buffer`。假如我们执行的是一个长期存活命令例如 `ping google.com`，那么除非命令中途出错退出，或者命令在 `stdout` 产生的信息达到了调用命令时设定的允许的 `buffer` 最大值（默认 1024x1024），否则我们没有直接的办法能够看到命令的是**实时输出**。

- `spawn()` 通常直接使用返回结果——一个 [ChildProcess](https://nodejs.org/api/child_process.html#child_process_class_childprocess) 实例。例如：

  ```javascript
  const cp = spawn('echo', ['google.com']);

  cp.stdout.on('data', chunk => {
    console.log('chunk:', chunk.toString());
  })
  ```

  在返回的 `ChildProcess` 实例对象上具有 `stdout` `stderr` 这两个可读流(ReadableStream)，想要获得被执行命令的输出结果，只能通过监听流的数据写入事件得知。同上面的 `exec` 对比可知，当我们希望能够**实时获取**子进程命令执行结果的时候，用 `spawn` 会更加的合适。

## 同步版本

`exec` 和 `spawn` 各自拥有其同步版本的方法 `execSync` 和 `spawnSync`。我们知道，同步代码意味着阻塞，意味着在同步调用之后的代码，应该能确定前面的代码意图是执行完成。例如：

```javascript
const a = execSync('echo google.com');
console.log(a.toString());   //  google.com

const b = spawnSync('echo', ['google.com']);
console.log(b.stdout.toString())  //  google.com
```

换成会长期存活的命令试一试：

```javascript
var a = exec('ping google.com');
console.log(a.toString());

// OR:
// var b = spawn('ping', ['google.com']);
// console.log('b...', b.stdout.toString());
```

结果如预期所想的那样，程序一直到出错前都没有输出任何实时的信息。这说明在同步调用时，两种方式基本形式达成了一致。

## References

- <https://nodejs.org/api/child_process.html#child_process_child_process_exec_command_options_callback>
- <https://www.hacksparrow.com/nodejs/difference-between-spawn-and-exec-of-node-js-child-rocess.html>
