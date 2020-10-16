---
layout: post
title:  Electron 应用内存占用分析及调优
link: memory-usage-of-an-electron-app
date:   2020-07-30 21:47:00 +0800
categories: nodejs
---

Electron 应用作为浏览器与 node 程序的融合体，其内存模型兼具有两者的特点：

![](/img/2020-10-16/electron-mem.png)

其中有以下需要了解的内存概念和度量方法：

## RSS

[RSS](https://nodejs.org/api/process.html) (Resident Set Size 常驻内存集)，node 进程运行时所有被分配的内存，可以通过 process.memoryUsage() 获取。

以下是某应用启动后各进程的 RSS：

|进程|size(byte)|size(mb)|
|---|---|---|
|主进程|	221667328|	211|
|渲染进程窗口|	254504960|	242.71|

RSS 虽然代表着进程总共占用的内存大小，但对 Electron 应用来说，它并不能实际反应该应用是否真实需要用到多少内存：

1. Chromium 会检测有多少内存可用，并且尽可能的利用这些内存以优化渲染页面时的体验，所以 RSS 可能总体上会显得特别高；
2. 当系统其他应用需要使用系统内存时，Chromium 会相应的释放掉部分内存（[参考](https://chromium.googlesource.com/chromium/src.git/+/master/docs/memory/key_concepts.md)）；
3. 由于 Chromium 的多页面进程模型以及共享内存的存在，各进程的内存占用之和会比整个应用的实际内存占用高的多（[参考](https://blog.chromium.org/2008/09/google-chrome-memory-usage-good-and-bad.html#:~:text=While%20the%20multi%2Dprocess%20model,tabs%20cannot%20share%20information%20easily.)）；

结论：

1. 对 Electron 应用来说，只要系统允许且有内存富余，总内存偏高属于正常情况；
2. RSS 由于可能包含渲染的共享内存以及易变，不具备参考性。

## Heap

nodejs 语言引擎 V8 实际用来存储对象、字符串、函数等的引用的内存占用（[参考](https://stackoverflow.com/questions/12023359/what-do-the-return-values-of-node-js-process-memoryusage-stand-for)）也可以通过 `process.memoryUsage()` 获取。

以下是某应用启动稳定后的 HeapUsed 占用：

|进程|size(byte)|size(mb)|
|---|---|---|
|主进程|	41871544|	39|
|渲染进程窗口|	46706648|	44.54|

该内存也可以通过 `chrome devtools` 内的 `Memory` 选项卡去采集快照并进行分析，可用来查找未释放的引用以定位内存泄漏问题。

## WebFrame Resources

Electron 页面的渲染引擎（[Blink](https://www.chromium.org/blink)) 所使用的资源缓存，例如 `images` `css` `fonts` `scripts` 等，可以通过 electron 渲染进程的 API `webFrame.getResourceUsage()` 获取。

以下是某一时刻某应用窗口渲染资源内存：

|type|size(byte)|size(mb)|
|---|---|---|
|images|	127918151|	121.99|
|css|	1586078|	1.51|
|scripts|13469039|12.84|

通过手动调用 `webFrame.clearCache()` 手动清理掉缓存资源后，以上内存占用将被释放，且此时查看 RSS 可以看到内存占用会有相应的降低量。

## Blink Memories

Electron 页面的渲染引擎 Blink 所使用的内存，和渲染/DOM元素相关。可以通过 electron 提供的 API `process.getBlinkMemoryInfo()` 获取。

## 优化手段

通过以上分析我们大致可以得出优化 Electron 应用内存占用的基本方式如下：

![](/img/2020-10-16/electron-mem-improve.png)

- 降低代码规模：
  - 优化编译打包配置，例如渲染资源(jpg, png, svg等)从代码中剥离，按需加载
  - 模块分析，移除无用的的模块，将较重的模块替换为更轻量的实现
- 避免内存泄漏：
  - 通过主进程、渲染进程的 HeapUsed 内存快照比较，排查内存泄漏
- 减少窗口数量
  - 改进架构，将通用的 SPA 形式的页面拆分为多个小的独立页面实现，轻量化资源占用
  - 如果足够轻量，可考虑使用时才创建窗口
- 释放渲染缓存
  - 定期（或者按需）调用 webFrame 的缓存清理
- 采集观测数据
  - 采集观测主进程、渲染进程内发生某些用户行为时 RSS、HeapUsed 趋势，充分掌握应用性能状况

## References

- <https://www.electronjs.org/docs/tutorial/performance>
- <https://blog.scottlogic.com/2019/05/21/analysing-electron-performance-chromium-tracing.html>
- <http://seenaburns.com/debugging-electron-memory-usage/>
- <https://github.com/bytedance/debugtron>
- <https://rollout.io/blog/understanding-garbage-collection-in-node-js/>
- <https://stackoverflow.com/questions/12023359/what-do-the-return-values-of-node-js-process-memoryusage-stand-for>
- <https://blog.chromium.org/2008/09/google-chrome-memory-usage-good-and-bad.html#:~:text=While%20the%20multi%2Dprocess%20model,tabs%20cannot%20share%20information%20easily.>
- <https://docs.microsoft.com/en-us/microsoftteams/teams-memory-usage-perf>
- <http://frozeman.de/blog/2013/08/why-is-svg-so-slow/>
- <https://kwonoj.github.io/en/post/electron-content-trace/>
