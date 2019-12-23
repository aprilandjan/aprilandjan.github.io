---
layout: post
title:  async 转换为 sync
link:   turn-async-into-sync
date:   2019-12-13 21:14:00 +0800
categories: javascript
---

编写一段异步代码总是很容易的。以下是一些可能的方式方法：

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

那么，如何将一段异步代码转换为同步？首先想到的是利用 `while` 循环去填充 js 执行，达到在启动某个`'异步'`任务后阻塞其他代码执行的效果：

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
    // do nothing
  }
}

(() => {
  console.log('a');
  test(wait(1000));
  console.log('b')
})();
```

这段代码执行后并没有希望中的按顺序输出 `a` `async done` `b`，而是在打印出字符 `a` 之后程序一直停留在 `while(!resolved)` 的循环内执行下去，不会结束，也不会打印出 `async done`。这说明 `while(true)` 语句的却是阻塞了其他的代码——也包括它前面的 `p.finally`。其实也很符合逻辑：假如它不能阻塞前面 `Promise` 的执行，那就肯定也无法阻塞其他的代码块执行了。既然这样，那类似 `nodejs` 里的 `fs.writeFileSync` 以及 `fs.writeFile` 它们是如何能做到既能同步又能异步的呢？

## 事件循环

先回顾一下 javascript 中的一个概念：`事件循环(Event Loop)`。我们都知道，javascript 是单线程执行的。在代码运行的过程中，维持着一个叫做 `调用栈(Call Stack)` 的数据结构，用以追踪当前正在执行的函数以及接下来要执行的函数。`栈(Stack)` 是一种数组，数据遵循 `先进后出(FILO, First-In-Last-Out)` 的规则。当执行函数时，函数上下文被添加到该调用栈内；当在该函数内再次调用了其他的函数时，其他函数也被添加到该调用栈的顶部；当函数结束完毕时，栈顶的函数上下文将被释放。当然，如果执行过程中发生了 `异常(Exception)`，通常会抛出错误，并附带上该错误产生时的完整的当前函数调用栈信息——这也就是 `错误栈(Error Stack)` 的含义。

但是 `javascript` 里也有很多异步的实现，例如 `setTimeout`，`process.nextTick`，`promise` 等。它们是怎么工作的呢？在这些异步操作被定义后，操作的回调并不是直接的添加到当前的调用栈当中去立即执行，而是把相应的 `事件(Event)` 以 `先进先出(FIFO, First-In-First-Out)` 的形式添加到事件队列中，等待恰当的时机来临时去执行这些异步操作的定义的回调。那么，这里这个“恰当的时机”怎样才能来临呢？

回到事件循环上来。可以把 `javascript` 的 `运行时(runtime)` 想象成一个时钟，它拥有一个 `定时周期(tick)` 并且每个周期都要执行去做以下工作：检查此刻的调用栈看是否为空。如果调用栈为空（即当前要执行的代码都已执行完），则从上面的事件表中找到满足其触发时机（满足的定时间隔，或者是输入输出等）的事件，并将对应事件的回调添加到调用栈中执行；如果没有满足的事件，那么该周期什么都不执行，等待下一个定时周期来临时再次执行检测。这个过程一直进行下去，就是所谓的事件循环。

事件循环为 `非阻塞(Non-Blocking)` 行为提供了条件。上文提及的各种异步行为，都是非阻塞行为的具体应用。

有了这些概念，再回到上面我们尝试实现的“将异步转换为同步”的代码中来，可以更清晰的认知到：`while(!resolved)` 由于一直在占用当前的调用栈不结束，因此事件循环停留在了这一个操作所处的阶段里；而 `p.finally` 的触发执行要等待事件循环进入后续的阶段，一直无法达到。因此以上尝试的代码不能起到预想的效果。

## DeAsync

好了，既然知道了 `node` 自身的事件循环会按上面分析的过程执行代码，那究竟有没有办法去实现异步转同步？这里的关键在于，如何能在阻塞后续 `javascript` 代码执行的情况下不阻塞整个线程，并且允许事件循环过程中的事件队列能够被照常处理——相当于是改变了 `javascript` 默认的事件循环处理流程！在 `nodejs` 里，由于能通过 `Native C++ Binding` 调用底层关于 `Event Loop` 的某些实现，还真能能达成这种效果。例如，模块 [DeAsync](https://github.com/abbr/deasync) 实现了这种阻塞策略。用它来加工上面的测试代码如下：

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
    //  meanwhile allow other event executing
    require('deasync').sleep(100);
  }
}

(() => {
  console.log('a');
  test(wait(1000));
  console.log('b')
})();
```

执行后输出依次为：`a` `async done` `b`，完美的达成了异步转同步的目标。

## 总结

虽然如此编码可能在实际中很难用到，但了解事件循环的这个过程本身就令人受益匪浅。

## 参考

- <https://developer.mozilla.org/en-US/docs/Web/JavaScript/EventLoop>
- <https://nodejs.org/de/docs/guides/event-loop-timers-and-nexttick/>
- <https://blog.logrocket.com/a-complete-guide-to-the-node-js-event-loop/>
- <https://hackernoon.com/understanding-js-the-event-loop-959beae3ac40>
- <https://github.com/abbr/deasync>
