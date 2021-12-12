---
layout: post
title: difference between node child process stdio inherit and pipe
link: difference-between-node-child-process-stdio-inherit-and-pipe
date: 2021-12-09 11:26:00 +0800
categories: nodejs
---

在 `nodejs` 中启动子进程时，可以通过参数 `stdio` 设置子进程与父进程间建立的输入输出关系。之前曾写过一些子进程的调用代码，总是习惯性的将这个参数设置为 `inherit`，但是没有仔细去了解其不同参数的区别。以下通过一些试验性质的代码对此进行了解、验证。

## 什么是 `stdio`

首先需要对 `stdio` 有一个初步的了解。`stdio` 全称为标准输入输出流(`Standard I/O`)，由标准输入(`stdin`)、标准输出(`stdout`)、标准错误(`stderr`)三个部分组成。最早它代表着系统的一些硬件设备间的联系，例如键盘作为输入，显示器作为输出；后来由此抽象成标准流，当一个程序运行时，`stdin` 可以是一个文本终端，`stdout` 可以是其他文件甚至其他流等。

### `stdin`

程序运行时可能需要读取并录入信息；通常它的信息来源为继承自父进程，追根溯源的话，可能就是一个能够读取键盘操作的程序。`stdin` 的文件描述符为 `0`。

在 `nodejs` 中，可以通过 `process.stdin` 的数据事件，或者是 `readline` 等 API 获取输入信息。

### `stdout`

程序也可能需要写入并输出信息；通常它将输出的信息显示在运行该程序的某个文本终端里。`stdout` 的文件描述符为 `1`。

在 `nodejs` 中，通过 `console.log` 打印的信息，本质上即是通过进程的 `stdout` 输出给父进程。

### `stderr`

`stderr` 和 `stdout` 本质上并没有区别，它仅仅是一个专门用于进程输出诊断信息的流，例如程序可以将它的错误信息都统一定向到某个错误日志文件里，但是一般的信息还是可以通过别的渠道去处理。`stderr` 的文件描述符为 `2`。

在 `nodejs` 中，通过 `console.warn`、`console.error` 打印的信息，都会通过 `stderr` 输出给父进程。

通过以上的标准输入输出的了解，我们可以有以下猜想：

1. 如果希望子进程能接收到父进程收到的外部输入（例如键盘输入等）信息，需要给子进程的 `stdin` 写入这部分数据；
2. 如果希望子进程产生的输出（`stdout`，`stderr`）通过父进程获取到，并且作为父进程输出的一部分一并输出给外部（例如文本终端等），需要能监听到子进程的这些输出，再在父进程中一并输出。

## `nodejs` 中子进程的 `stdio`

`nodejs` 已通过调用子进程时的 `stdio` 参数项提供了一些控制父子进程间输出输出流通信行为的方法，以下通过一些试验性质的代码对此进行了解、验证。

首先是一段共享代码，它将在父子进程中都被调用，用于保持进程存活、监听 `stdin` 数据、产生 `stdout` 信息：

```js
// shared.js
module.exports = (name) => {
  // without this, we would only get streams once enter is pressed
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
  }
  // resume stdin in the parent process (node app won't quit all by itself
  // unless an error or process.exit() happens)
  process.stdin.resume();
  // i don't want binary
  process.stdin.setEncoding('utf-8');
  // on any data into stdin
  process.stdin.on('data', (key) => {
    // ctrl-c ( end of text )
    if ( key === '\u0003' ) {
      process.exit();
    }
    // write the key to stdout all normal like
    process.stdout.write( `${name} input: ${key}\n` );
  });

  setInterval(() => {
    console.log(`${name} interval output`, Date.now());
  }, 1000);
}
```

子进程代码，它只需要简单的引用上面的 `shared.js` 即可：

```js
// child.js
const shared = require('./shared');
shared('child process');
```

父进程代码，除了上面的 `shared.js` 调用，通过 `fork` 调起子进程，并通过 `stdio` 参数项控制输入输出行为：

```js
// parent.js
const { fork } = require('child_process');
const shared = require('./shared');

shared('parent process');

const cp = fork('./fork.js', {
  stdio: 'pipe', // or any other acceptable values
});
```

接下来我们会调整不同的 `stdio` 配置值（以及相关方法）以观察其区别。

## `stdio: "pipe"`

首先是默认参数值 `pipe`。根据 `nodejs` 官方文档说明：

> the child's stdin, stdout, and stderr are redirected to corresponding subprocess.stdin, subprocess.stdout, and subprocess.stderr streams on the ChildProcess object.

> 'pipe': Create a pipe between the child process and the parent process. The parent end of the pipe is exposed to the parent as a property on the child_process object as subprocess.stdio[fd]. Pipes created for fds 0, 1, and 2 are also available as subprocess.stdin, subprocess.stdout and subprocess.stderr, respectively.

启动程序并观察控制台输出：

```bash
$ node ./parent.js
parent process interval output 1639314028386
parent process interval output 1639314029393
parent process interval output 1639314030398
...
```

控制台里并没有子进程的输出信息。根据上文的官方说明可知，此时子进程的输出被导向 `child_process` 实例的 `stdio` 对象（即 `cp.stdin`, `cp.stdout`, `cp.stderr` 三个流）上。由于我们没有对这些流做任何操作，所以目前无法了解到子进程运行的状态。尝试给子进程对象加上输出流的数据监听：

```js
// parent.js
const { fork } = require('child_process');
const shared = require('./shared');

shared('parent process');

const cp = fork('./fork.js', {
  stdio: 'pipe', // or any other acceptable values
});

cp.stdout.on('data', (data) => {
  console.log('parent process got child process output:', data.toString());
});
```

运行后输出如下：

```bash
$ node ./parent.js
parent process interval output 1639314426782
parent process got child process output: child process interval output 1639314426828

parent process interval output 1639314427791
parent process got child process output: child process interval output 1639314427838

parent process interval output 1639314428795
parent process got child process output: child process interval output 1639314428841
```

此时父进程获取到了子进程的输出信息，并可以自由使用，例如输出到自身的标准输出。接下来我们尝试通过按键往父进程的标准输入内写入数据，并观察父子进程的行为：

```bash
$ node ./parent.js
parent process interval output 1639314810770
parent process got child process output: child process interval output 1639314810815

parent process input: a
```

按键输入字符 <kbd>a</kbd> 后，父进程通过其 `stdin` 成功抓取到了输入内容，但子进程似乎对此并没有响应。我们尝试在此时手动对 `cp.stdin` 做数据写入：

```js
const fork = require('child_process').fork;
const shared = require('./shared');

shared('parent process');

const cp = fork('./child.js', {
  stdio: 'pipe',
});

cp.stdout.on('data', (data) => {
  console.log('parent process got child process output:', data.toString());
});

process.stdin.on('data', (key) => {
  cp.stdin.write(key);
});
```

启动程序，随意输入并观察控制台输出：

```bash
$ node ./parent.js
parent process interval output 1639315246452
parent process got child process output: child process interval output 1639315246483

parent process input: a
parent process got child process output: child process input: a
```

此时子进程内成功的抓取到了输入内容，并进行响应。可见，`pipe` 这种模式将子进程的 `stdio` 导向 `child_process` 实例的 `stdio` 流对象上，并没有其他的默认行为。任何需要操作子进程 `stdio` 的行为，都需要通过这几个流对象上的相关方法手动执行。总的来说，可以认为是一种自助式操作。

## `stdio: "inherit"`

接下来尝试换成 `inherit` 模式启动子进程。直接修改 `stdio: "pipe"` 为 `stdio: "inherit"` 并启动，程序直接报错退出：

```bash
$ node ./parent.js
cp.stdout.on('data', (data) => {
          ^

TypeError: Cannot read properties of null (reading 'on')
...
```

可见此时 `cp` 实例上已然没有 `stdout` 等输出输出流对象。根据官方文档说明：

> 'inherit': Pass through the corresponding stdio stream to/from the parent process. In the first three positions, this is equivalent to process.stdin, process.stdout, and process.stderr, respectively. In any other position, equivalent to 'ignore'.

在 `inherit` 模式下，父子进程各自的 `stdio` 会直接互相传递。我们去掉上面的报错代码，再进行尝试：

```js
// parent.js
const fork = require('child_process').fork;
const shared = require('./shared');

shared('parent process');

const cp = fork('./child.js', {
  stdio: 'inherit',
});

```

启动程序，随意输入并观察控制台输出：

```bash
$ node ./parent.js
parent process interval output 1639316215826
child process interval output 1639316215858
child process input: s
parent process input: a
```

可以看到，父子进程的 `stdout` 内容现在会合并为整个进程的输出内容打印出来，无需我们显示的去监听或者处理；输入随机字符时，有时显示为子进程抓取到了该输入，有时显示为父进程，但没有父子进程同时监听到同一个字符输入并处理的情况，似乎可以认为，`stdin` 现在也只有父子进程共用的一份，在父子进程都想抓取输入内容时，存在一定的不确定性。尝试取消掉对父进程的 `stdin` 的监听，以验证该结论：

```js
const fork = require('child_process').fork;

const cp = fork('./child.js', {
  stdio: 'inherit',
});
```

启动程序，随意输入并观察控制台输出：

```bash
$ node ./parent.js
child process interval output 1639316608546
child process input: s
child process input: a
child process input: b
```

此时每一个输入字符都准确的被子进程所捕获，似乎可以验证上面的猜想，即父子进程共用同一份 `stdin`。再结合官方文档上言简意赅的说明，可以将 `inherit` 模式理解为：

1. 父进程的 `stdin` 收到的数据自动导向子进程的 `stdin`（但只有一个其中一个进程可以读取并消费）；
2. 子进程的 `stdout`/`stderr` 产生的数据自动的导向父进程的 `stdout`/`stderr`（并和父进程自身的输出内容合并在一起整体输出）。
3. 由于该模式下已自动处理了子进程的输入输出流的行为，`cp` 对象此时不再提供这些流的访问操作能力。

## Summary

通过以上的试验，我们对如何控制并使用 `nodejs` 中进程的标准输入输出流有了更清晰的了解。当需要让例如键盘输入之类的操作“透传”到子进程去处理时，可以使用 `stdio: "inherit"`；当需要在父进程对子进程的输出内容做分析、转换、过滤等操作时，可以使用 `stdio: "pipe"`（并结合相应子进程实例上提供的流对象方法）；当以上两种诉求都需要时，甚至也可以单独控制其各自的行为，例如：`stdio: ["inherit", "pipe", "pipe"]`。

## References

- <https://en.wikipedia.org/wiki/Standard_streams>
- <https://nodejs.org/api/child_process.html#optionsstdio>
- <https://stackoverflow.com/questions/50045741/difference-between-inherit-and-process-pipe-child>
- <https://stackoverflow.com/questions/5006821/nodejs-how-to-read-keystrokes-from-stdin/12506613#12506613>
