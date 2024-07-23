---
layout: post
title:  没用的知识+1 - 异步转同步
link:   turn-async-into-sync
date:   2019-12-13 21:14:00 +0800
categories: node.js
---

在 node.js 中，编写一段异步代码总是很容易的。以下是一些可行的方式方法：

```js
// 1. callback
function wait(t, callback) {
  setTimeout(() => {
    callback(t);
  }, t);
}
wait(1000, (t) => {
  console.log('time passed', t);
})

//  2. promise
function wait(t) {
  return new Promise((resolve) => setTimeout(() => resolve(t), t));
}
wait(1000).then(t => {
  console.log('time passed', t)
})

//  3.  generator
function *wait(t) {
  const r = yield new Promise(resolve => setTimeout(() => {
      resolve(t);
  }, t));
  return r;
}
((gen) => {
  const g = gen(1000);
  function run (arg) {
    const result = g.next(arg);
    if (result.done) {
      return result.value;
    } else {
        //  wait until promise resolve
      return Promise.resolve(result.value).then(run);
    }
  }
  return run();
})(wait).then(t => {
  console.log('time passed', t);
});

//  4. async await
function wait(t) {
  await new Promise(resolve => setTimeout(resolve, t));
  return t;
}
(async () => {
  const t = await wait(1000);
  console.log('time passed', t);
})();
```

node.js 生态中也提供了各种形式的异步调用方法。拿文件操作举例，在 node.js 中我们既可以选择使用同步版本，也可以选择异步版本：

```js
// 同步版本
const fs = require('fs');
fs.writeFileSync('/path/to/file.txt', 'hello');
console.log('file written');

// 异步版本
const fs = require('fs/promises');
fs.writeFile('/path/to/file.txt', 'hello').then(() => {
  console.log('file written');
});
doSomethingElse();
```

假设现在有这样一种场景：我们现在只能使用异步方法，但是希望在执行该异步方法的过程中，阻止任何其他代码运行（以避免任何可能的潜在影响）。那么，一个有趣的问题浮出水面：有没有办法将一段异步代码转换为同步代码执行？

## while(!resolved)

首先想到的是用 `while` 循环去填充 js 执行，尝试达到在开启某个异步任务后立即阻塞其他代码执行的效果：

```js
function wait (t) {
  return new Promise(resolve => setTimeout(resolve, t));
}

function test(p) {
  let resolved = false;
  p.finally(() => {
    console.log('async done');
    resolved = true;
  })

  // 自旋并等待异步操作 p 结束
  while(!resolved) {
    // do nothing
  }
}

(() => {
  console.log('a');
  test(wait(1000));
  console.log('b')
})();
```

这段代码并没有按希望的顺序输出 `a` `async done` `b`，而是在打印出字符 `a` 之后一直停留在 `while(!resolved)` 的循环内执行下去，没有打印出任何其他信息。这说明 `while(true)` 语句的确阻塞了其他的代码——也包括它前面的 `p.finally`。这也很合乎逻辑：假如它不能阻塞前面 `Promise` 的执行，那肯定也就无法阻塞其他的代码块执行了。为什么异步明明已在 1s 后结束了，却没有机会执行呢？

既然这样，那类似 `nodejs` 里的 `fs.writeFileSync` 以及 `fs.writeFile` 它们是如何能做到既能同步又能异步的呢？

## 非阻塞的本质

我们都知道，js 是单线程执行的。在这个所谓的“单线程”中，维持着一个叫做调用栈(Call Stack)的数据结构，用以追踪当前正在执行的函数以及接下来要执行的函数。栈(Stack)是一种数组，数据遵循先进后出(FILO, First-In-Last-Out)的规则。当执行函数时，函数上下文被添加到该调用栈内；当在该函数内再次调用了其他的函数时，其他函数也被添加到该调用栈的顶部；当函数结束完毕时，栈顶的函数上下文将被释放。当然，如果执行过程中发生了异常(Exception)，通常会抛出错误，并附带上该错误产生时的完整的当前函数调用栈信息——这也就是错误栈(Error Stack)的含义。

前文提到的各种异步调用，例如 `setTimeout`，`process.nextTick`，`promise` 等，它们是怎样嵌入到调用栈中工作？在这些异步操作被定义后，本质上是注册了一个回调行为。回调并不是在达到触发条件时直接的添加到当前的调用栈当中去立即执行，而是注册为事件(Event)以先进先出(FIFO, First-In-First-Out) 的形式添加到**任务队列(Task Queue)**中，等待恰当的的触发时机的到来。

可以把 js 的运行时(runtime) 想象成一个时钟，它拥有一个定时周期(tick)并且每个周期都要执行去做以下工作：检查当前的调用栈看是否为空。如果调用栈为空（即当前需要执行的代码都已执行完），则从上面的全局事件队列中找到能满足其触发时机（满足的定时间隔，或者是输入输出等）的事件，并将对应事件的回调添加到调用栈中执行。如果没有满足的事件，那么该周期什么都不执行，等待下一个定时周期来临时再次执行检测。这个过程一直进行下去，就是所谓的事件循环(Event Loop)：

```
   ┌───────────────────────────┐
┌─>│           timers          │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │     pending callbacks     │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │       idle, prepare       │
│  └─────────────┬─────────────┘      ┌───────────────┐
│  ┌─────────────┴─────────────┐      │   incoming:   │
│  │           poll            │<─────┤  connections, │
│  └─────────────┬─────────────┘      │   data, etc.  │
│  ┌─────────────┴─────────────┐      └───────────────┘
│  │           check           │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
└──┤      close callbacks      │
   └───────────────────────────┘
```

事件循环机制为 node.js 的非阻塞(Non-Blocking)运行提供了条件。有了这些概念，再回到上面尝试实现的“将异步转换为同步”的代码中来，可以更清晰的认识到：由于 `while(!resolved)` 在持续占用当前的调用栈，事件循环陷入了等待调用栈清空的过程中；而 `p.finally` 的触发执行要等待事件循环进入任务队列的消费阶段，因此以上尝试的代码不能起到预想的效果。

真的能做到异步转同步吗？

## DeAsync

我们需要一种手段去实现在不阻塞整个线程的情况下，在允许事件循环中的**任务队列**消费的同时，实现对后续代码执行的阻塞——这相当于是改变了 node.js 默认的事件循环流程。万能的 Github 给了我们解决办法：[DeAsync](https://github.com/abbr/deasync) 即可实现异步转同步。快速验证一下：

```js
function wait (t) {
  return new Promise(resolve => setTimeout(resolve, t));
}

function test(p) {
  let resolved = false;
  p.finally(() => {
    console.log('async done');
    resolved = true;
  })
  while(!resolved) {
    //  just block while for some time
    //  meanwhile allow task queue executing
    require('deasync').sleep(100);
  }
}

(() => {
  console.log('a');
  test(wait(1000));
  console.log('b')
})();
```

执行后，输出依次为：`a` `async done` `b`，成功达成了预期的效果。你可能会很好奇它究竟是怎么做到的。实际上，`deasync` 是一个 node.js 源生模块，它的实现非常精简，关键代码只有一行：

```cpp
uv_run(node::GetCurrentEventLoop(v8::Isolate::GetCurrent()), UV_RUN_ONCE);
```

这段代码实现了手动驱动(`uv_run`)当前的事件循环实例(`node::GetCurrentEventLoop(v8::Isolate::GetCurrent())`)阻塞式运行一轮迭代(`UV_RUN_ONCE`)的功能。`deasync.sleep` 实际上使得当前调用栈在指定时间中陷入重复的手动驱动事件循环的过程中，从而达成阻塞后续代码执行的同时又允许事件循环中的**任务队列**继续消费的目的。

你可能会发现，这其实还是和真正的完全阻塞式的同步不能完全等同。例如，以下代码在等待异步转同步执行结束中间，被非预期的插入了其他的任务：

```js
// test.js
function wait (t) {
  return new Promise(resolve => setTimeout(resolve, t));
}

function test(p) {
  let resolved = false;
  p.finally(() => {
    console.log('async done');
    resolved = true;
  })
  while(!resolved) {
    //  just block while for some time
    //  meanwhile allow task queue executing
    require('deasync').sleep(100);
    // sleepAndTick(100);
  }
}

wait(500).then(() => {
  console.log('500 done');
});

(() => {
  console.log('a');
  test(wait(1000));
  console.log('b')
})();

wait(400).then(() => {
  console.log('400 done');
});
```

输出结果：

```bash
$ node ./test.js
a
500 done
async done
b
400 done
```

程序输出的结果相当奇怪。但结合上面介绍的实现原理，相信你一定能理解这看起来乱了套的结果的原因。

## 总结

虽然我们可能永远都不会真的有异步方法转同步执行的诉求，但通过这个探索的过程了解 node.js 非阻塞式运行的本质也别有乐趣。没用的小知识再次 +1。

## 参考

- <https://developer.mozilla.org/en-US/docs/Web/JavaScript/EventLoop>
- <https://html.spec.whatwg.org/multipage/webappapis.html#task-queue>
- <https://nodejs.org/de/docs/guides/event-loop-timers-and-nexttick/>
- <https://blog.logrocket.com/a-complete-guide-to-the-node-js-event-loop/>
- <https://hackernoon.com/understanding-js-the-event-loop-959beae3ac40>
- <https://github.com/abbr/deasync>
- <https://github.com/laverdet/node-fibers>
