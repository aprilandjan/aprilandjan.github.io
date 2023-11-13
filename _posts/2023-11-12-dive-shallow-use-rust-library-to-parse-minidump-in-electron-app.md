---
layout: post
title: 牛刀小试：electron 中调用 rust 模块解析崩溃文件
link: dive-shallow-use-rust-library-to-parse-minidump-in-electron-app
date:   2023-11-12 20:00:00 +0800
categories: node.js rust
---

> 是🦀，我加了🦀

## 背景

对于一个 electron 应用来说，使用框架自带的 `crashReporter` API 捕获应用进程的崩溃实在是太容易不过了：

```ts
import { crashReporter } from 'electron';

crashReporter.start();
```

设置后，应用会启动一个独立的监听进程，在应用的其他进程发生崩溃时，该监听进程会捕获到这些进程的崩溃信息，并将转储文件（实际上是 minidump 文件）写入到特定的崩溃目录中。如果应用同时也接入了一些崩溃采集服务（例如 sentry），这些 dump 文件也会被上传到服务器进行解析、符号表映射、分类归档，供开发者分析、排查。（...and more in real user case）

(图片：描述崩溃采集->本地文件->服务端记录)
（https://chromium.googlesource.com/crashpad/crashpad/+/refs/heads/main/doc/overview_design.md）

由于 electron 应用的多进程特性，崩溃目录中的文件，既可能是来自于框架的**辅助进程**例如 Network Service、GPU Service（框架会自动重新拉起辅助进程），也可能来自于某个功能的 **node.js 子进程**（业务实现上会做异常处理），而不是用户可感知应用存活所依赖的**主进程**或**窗口进程**——这给我们采集上报、计算应用的真实崩溃率造成了很大的困扰：如何准确的获取这些崩溃文件对应的进程类别？

在接入了较新版本的 Sentry 服务后，我们发现 Sentry 上的崩溃记录详情中，新增了发生崩溃的进程和系统的相关信息：

（图片：Sentry 的某个崩溃信息详情）

这带给我们以启发：既然 Sentry 能解出这些崩溃文件中的进程信息，那我们是否可以在客户端侧也进行崩溃文件解析，从而在端侧准确的获得客户端的真实崩溃情况，做一些针对性的判断、帮助提示或优化？

## 可行性

electron 中的 `crash-reporter` 实际上使用的是 chromium 开源工程中的 `crashpad`。根据源码及文档，我们可以编译出对应平台的可执行的解析程序。但我们更希望的是一种可供编程式调用的接口，这点官方并未提供。开源社区中虽然有一个 `node-minidump`，但它本质上也只是上述编译产物的套壳，不满足我们的使用设想。好在 Sentry 也是完全开源的，从它入手，看看它是怎么做的：

（图片：sentry 部署架构图）

显然，`Symbolicator` 即是负责处理崩溃文件的服务节点。该服务使用了 [symbolic](https://github.com/getsentry/symbolic) 作为解析工具，而 `symbolic` 是 Sentry 开发的一个集中解析各种常见应用崩溃的 rust 库，它调用 [rust-minidump](https://github.com/rust-minidump/rust-minidump) 解析 electron 等应用产出的 minidump 文件。

...

## 编写 rust->node.js binding

接下来我们开始编写在 electron 应用（其实是 node.js）中调用 rust 代码的 binding 代码。

...

## References

- <https://www.electronjs.org/docs/latest/api/crash-reporter>
- <https://chromium.googlesource.com/crashpad/crashpad/+/refs/heads/main/README.md>
- <https://github.com/getsentry/symbolicator>
- <https://github.com/neon-bindings/neon>
- <https://github.com/napi-rs/napi-rs>
