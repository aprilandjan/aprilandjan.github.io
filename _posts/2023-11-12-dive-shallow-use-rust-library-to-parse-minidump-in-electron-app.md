---
layout: post
title: 牛刀小试：electron 中调用 rust 模块解析崩溃文件
link: dive-shallow-use-rust-library-to-parse-minidump-in-electron-app
date:   2023-11-12 20:00:00 +0800
categories: node.js rust
---

> 是🦀，我加了🦀

## 崩溃文件的问题，它也是问题...

对于一个 electron 应用来说，使用框架自带的 `crashReporter` API 捕获应用进程的崩溃实在是太容易不过了：

```ts
import { crashReporter } from 'electron';

crashReporter.start();
```

设置后，应用会启动一个独立的监听进程，在应用的其他进程发生崩溃时，该监听进程会捕获到这些进程的崩溃信息，并将后缀名为 `.dmp` 的转储文件（实际上是 minidump 文件）写入到特定的崩溃目录中。如果应用同时也接入了一些崩溃采集服务（例如 sentry），这些 dump 文件也会被上传到服务器进行解析、符号表映射、分类归档，供开发者分析、排查。（...and more in real user case）

(图片：描述崩溃采集->本地文件->服务端记录)
（https://chromium.googlesource.com/crashpad/crashpad/+/refs/heads/main/doc/overview_design.md）

由于 electron 应用的多进程特性，崩溃目录中的文件，既可能是来自于框架的**辅助进程**例如 Network Service、GPU Service（框架会自动重新拉起辅助进程），也可能来自于某个功能的 **node.js 子进程**（业务实现上会做异常处理），而不是用户可感知应用存活所依赖的**主进程**或**窗口进程**——这给我们采集上报、计算应用的真实崩溃率造成了很大的困扰：如何准确的获取这些崩溃文件对应的进程类别？

在接入了较新版本的 Sentry 服务后，我们发现 Sentry 上的崩溃记录详情中，新增了发生崩溃的进程和系统的相关信息：

（图片：Sentry 的某个崩溃信息详情）

这带给我们以启发：既然 Sentry 能解出这些崩溃文件中的进程信息，那我们是否可以在客户端侧也进行崩溃文件解析，从而在端侧准确的获得客户端的真实崩溃情况，做一些针对性的判断、帮助提示或优化？

## 客户端侧解析崩溃，能不能行？

electron 中的 `crash-reporter` 实际上使用的是 chromium 开源工程中的 `crashpad`。根据源码及文档，我们可以编译出对应平台的可执行的解析程序。但我们更希望的是一种可供编程式调用的接口，这点官方并未提供。开源社区中虽然有一个 `node-minidump`，但它本质上也只是上述编译产物的套壳，不满足我们的使用预期。好在 Sentry 也是完全开源的，不妨从它入手，看看它是怎么做的：

（图片：sentry 部署架构图）

显然，图中的 `Symbolicator` 即是负责处理崩溃文件的服务节点。该服务使用了 [symbolic](https://github.com/getsentry/symbolic) 作为解析工具，而 `symbolic` 是 Sentry 团队开发的一个集中解析各种常见应用崩溃文件的 rust 库，它调用 [rust-minidump](https://github.com/rust-minidump/rust-minidump) 解析 electron 等应用产出的 minidump 文件。

根据文档，由于我们目前的诉求仅限于解析出 minidump 文件携带的进程信息，并不包括还原调用堆栈及符号表映射，使用最基本的 rust-minidump 就可以满足。接下来试着编写一段 rust 代码，验证是否可行（此处省略 5000 字仓促学习 rust 语法过程）：

```rust
use minidump::*;

fn main() -> Result<(), Error> {
    // Read the minidump from a file
    let mut dump = minidump::Minidump::read_path("../testdata/test.dmp")?;

    // Statically request (and require) several streams we care about:
    let system_info = dump.get_stream::<MinidumpSystemInfo>()?;
    let exception = dump.get_stream::<MinidumpException>()?;

    // Combine the contents of the streams to perform more refined analysis
    let crash_reason = exception.get_crash_reason(system_info.os, system_info.cpu);

    // Conditionally analyze a stream
    if let Ok(threads) = dump.get_stream::<MinidumpThreadList>() {
        // Use `Default` to try to make progress when a stream is missing.
        // This is especially natural for MinidumpMemoryList because
        // everything needs to handle memory lookups failing anyway.
        let mem = dump.get_memory().unwrap_or_default();

        for thread in &threads.threads {
            let stack = thread.stack_memory(&mem);
            // ...
        }
    }
    Ok(())
}
```

Bingo! 程序成功打印出了传入的崩溃文件的真实进程类型，可行性得到了验证。
接下来我们开始编写在 electron 应用（其实是 node.js 环境）中调用 rust 的拓展程序。

## 编写 node.js rust 拓展程序

写过 node.js C++ 拓展的小伙伴可能会知道，node.js 官方在 v8.0 版本后推出了 ABI-Stable 的 [napi](https://nodejs.org/api/n-api.html) 框架，保障其在所有的后续 node.js 版本中兼容。自此之后，社区活跃的源生模块纷纷迁往 `napi` 实现，彻底终结了以前 node.js 版本变化就不得不重编源生依赖的时代。但在调用 rust 代码方面，并没有这样的一套由 node.js 官方维护或推荐的框架。目前，rust 社区主要有以下三种 node.js rust 拓展框架，分别是:

- [neon-binding](https://github.com/neon-bindings/neon): 可能是 rust 社区最早的 node.js rust 拓展框架。我们熟悉的 rust 版的 babel——[swc](https://github.com/swc-project/swc) 早期的版本曾使用过它产出 node.js binding。不过似乎文档和教程都比较简单，上手实际运用门槛稍有点高。
- [napi-rs](https://github.com/napi-rs/napi-rs): 目前看起来活跃度最高、成熟案例最多的框架，提供了详实的文档和功能超乎强大的脚手架。上面说到的 swc 也于 20 年从 `neon` 迁移到了 `napi-rs`([ref](https://github.com/swc-project/swc/issues/852))。
- [node-bindgen](https://github.com/infinyon/node-bindgen): 目前看起来还比较小众，没有找到什么案例。

经过对比，我们决定选用 `napi-rs` 实现功能。`napi-rs` 已提供了一套完善度极高的脚手架工程 [napi-rs/package-template](https://github.com/napi-rs/package-template)，接下来我们利用它实现目标功能。

### 搭建工程模板

首先是准备好工程仓库。可以直接从该模板仓库上直接 clone 到本地：

```bash
$ git clone git@github.com:napi-rs/package-template.git
```

或者使用 github 页面上提供的 "Use this template" 创建仓库均可：

![use-repo-template](rs-minidump-repo-use-template.png)

> ⚠ 由于该模板工程使用的 swc 版本以及流水线配置里的运行环境的限制，以下开发过程均要求使用 node.js v18+ 以及 yarn v4+，如果你是 yarn classical 的遗老遗少，请先按需使用 nvm 配置好运行环境 :)。

接下来安装依赖，并且将模板工程中的模板项目名称换成自己的项目名：

```bash
$ yarn install
$ npx napi rename -n my-node-rs-lib
```

`napi` 是模板内提供的脚手架工程辅助工具，负责做将 rust 编译产物最终发布为 npm 包的一些工程化上的琐碎事项，例如读取约定的配置、构建产物移动到特定位置、修改版本号、批量发布各平台预编译的二进制文件等等。此处我们先手动使用它来重命名工程，避免发包时产生包名冲突。

IDE 提示 `<project>/npm/` 目录下很多子目录的文件都出现了 diff：

![alm](rs-minidump-repo-rename.png)

这些目录是做什么的？通过其名称，很容易猜到它们应该是当前工程编译到各个平台的**预编译二进制文件**（prebuilt binary）的发布目录。没错！该工程预配置了几乎所有主流平台架构的编译、发布能力。但目前，鉴于我们只想在 Windows/MacOS 的 electron 应用中使用，实在是不需要这么大而全的配置，可以直接做一些删减。在 `<project>/package.json` 中，修改 `napi` 配置项的值：

![Alt text](rs-minidump-repo-build-target.png)

在此，我们仅保留了 Windows x64/Windows ia32/MacOS Arm64/MacOS x64 这四种平台架构作为构建目标。需要特别注意的是 `defaults` 要调整为 `false` 以阻止其默认的平台产物构建，否则稍后发布过程中会有耗费你一小时 DEBUG 的神秘事件发生。相应的，`<project>/npm/` 目录下那些不需要的目标目录也都可以直接删除了。

> ⚠ 完整的可支持的编译目标平台代号列表，可参看 [rust platform support](https://doc.rust-lang.org/nightly/rustc/platform-support.html)

### 编码 & 验证


### 发布 & 使用


## References

- <https://www.electronjs.org/docs/latest/api/crash-reporter>
- <https://chromium.googlesource.com/crashpad/crashpad/+/refs/heads/main/README.md>
- <https://github.com/getsentry/symbolicator>
- <https://lyn.one/2020/09/11/rust-napi>
