---
layout: post
title: node.js 中进程的 argv 与 execArgv 的区别
link: difference-between-process-argv-and-execArgv-in-nodejs
date:   2023-11-10 20:00:00 +0800
categories: node.js
---

一直都以为 process.argv 包含了当前进程的完整命令行参数，child_process 中的 fork 等拉起子进程指定进程参数的方法也同样是可以指定任何命令行参数，例如:

```js
const cp = require('child_process');
cp.fork('./child.js', ['--inspect', '--key', '--key1=v1'], {
  stdio: 'inherit',
});
```

以上的代码中，给子进程指定了 `--inspect` 参数，以期能够开启该子进程的调试模式。但最近才发现这种写法根本不生效，非常令人困惑。查找资料对比之下，才发现原因，即：

1. `--inspect` `--inspect-brk` 等 `node.js` 专有的命令行参数，在 `node.js` 中被分类为 `execArgv`，不属于 `argv`。例如：

    ```bash
    # 以调试模式启动 repl node 进程
    $ node --inspect

    Debugger listening on ws://127.0.0.1:9229/411db276-52b3-48cb-98fb-f962ad64f3fd
    For help, see: https://nodejs.org/en/docs/inspector
    Welcome to Node.js v16.20.2.
    Type ".help" for more information.

    # 打印出 argv
    > process.argv
    [ 'C:\\path\\to\\node\\v16.20.2\\bin\\node.exe' ]

    # 打印出当前的 execArgv
    > process.execArgv
    [ '--inspect' ]
    ```

2. 想要在 `child_process` 中通过这些 `node.js` 专有的命令行参数影响其行为，需要使用第三个参数 `options.execArgv` 传入。

    ```js
    const cp = require('child_process');
    cp.fork('./child.js', ['--key', '--key1=v1'], {
      stdio: 'inherit',
      execArgv: ['--inspect-brk'], // !IMPORTANT: 调试参数附加在这里
    });
    ```

## References

- <https://nodejs.org/docs/latest/api/process.html#processargv>
- <https://nodejs.org/docs/latest/api/process.html#processexecargv>
