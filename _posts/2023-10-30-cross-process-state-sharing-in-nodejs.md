---
layout: post
title: node.js 中如何实现跨进程的状态共享
link: handling-message-boundary-in-nodejs-ipc
date:   2023-10-30 10:18:00 +0800
categories: node.js
---

## 背景

众所周知，node.js 由于其单线程执行的机制，通常只能有效利用单个 CPU 核心。当执行一些 CPU 密集型运算的操作时，很容易发生线程长时间阻塞带来的程序卡顿。然而，现代计算机处理器大都是多核心的，单线程不能充分利用多核资源，造成计算性能的浪费。

通常来说，想要利用多核心带来的算力提升，有以下几种方式：

1. 通过编写源生 C++ 模块拓展 node.js 可利用的线程。当执行特定的 CPU 密集型运算时，将任务移交给那些线程执行——事实上，node.js 中的 [crypto](https://nodejs.org/api/crypto.html) [zlib](https://nodejs.org/api/zlib.html#threadpool-usage-and-performance-considerations) 等模块已经是这样做的了；
2. 通过 [worker_threads](https://nodejs.org/api/worker_threads.html) 模块提供的多线程能力。类似 web worker，该方法也可以实现特定数据结构的内存共享传递；
3. 通过 [child_process](https://nodejs.org/api/child_process.html) 或 [cluster](https://nodejs.org/api/cluster.html) 模块启动多个进程实例。这些实例拥有各自独立的执行上下文、内存区块、生命周期，是一个完整的全功能的 node.js 进程。

结合在 electron 程序的实际开发需要，本文主要介绍基于 child_process 多进程模型下应用程序状态共享的一些思路和方法。

## 多个进程，多份状态

在单个进程内，很容易持有一份全局状态。这份状态唯一决策、驱动了上层业务，无论读取还是修改，都可以简单的同步执行：

```ts
// globalState.ts
const globalState: GlobalState = {
  //...
}

/** 获取某个全局状态 */
export function getState(key: string) {
  return globalState[key];
}

/** 设置某个全局状态 */
export function setState(key: string, value: any) {
  globalState[key] = value;
}
```

当把功能拓展到多个进程时，事情变得棘手起来。这多个进程可能都需要访问某些进程间彼此公用的数据，例如应用的全局配置、功能开关、缓存状态等等。此时，哪个进程持有的状态才值得信赖？访问状态是同步还是异步？某一个进程修改的状态，另外的进程如何感知？

## 哪个进程持有的状态才值得信赖？

必须有一个唯一决策源。假设

## 访问状态是同步还是异步？

## 初始状态如何传递？

## 如何感知到状态被修改？

## 如何保障一致性？

- <https://juejin.cn/post/6992091006220894215>