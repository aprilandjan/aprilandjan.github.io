---
layout: post
title: 浅谈 electron 应用的面临的安全风险
link: security-risks-of-electron-app
date:   2024-03-16 20:30:00 +0800
categories: electron
---

## 是 electron，也是 node

就像你所知道的那样，electron 应用可以理解为一个缝合了 Node.js 运行时的 Chrome 浏览器。但你可能不知道，electron 应用的可执行文件，在某些情况下可以当成一个单独的 Node.js 运行时程序使用。以 vscode 为例：

```bash
$ export ELECTRON_RUN_AS_NODE=1
$ cd "$(dirname "$(which oracle)")
$ ./Code.exe -e "console.log(Date.now())"
1710664724110
```

通过加上环境变量 `ELECTRON_RUN_AS_NODE`，我们将 vscode 的可执行程序 Code.exe 用作了 Node.js 运行时，并执行了一段脚本，打印出了当前的时间戳。

除此之外，Node.js 特有的一些[命令行参数](https://nodejs.org/api/cli.html#options)例如开启调试模式的 `--inspect`, `--inspect-brk` 等也可以被使用。还是以 vscode 为例：

```bash
$ ./Code.exe --inspect-brk

Debugger listening on ws://127.0.0.1:9229/278434b6-eab5-4600-bacf-fa2a75ea9597
For help, see: https://nodejs.org/en/docs/inspector
```

`--inspect-brk` 是启动 Node.js 并自动断点在第一行代码的参数。通过控制台信息，可以看到 vscode 已以调试模式启动。接下来可以直接使用 Chrome Devtools 挂载调试器到该进程并进行调试：

![debug vscode](/img/2024-03-17/electron-security-inspect.png)

## 便利还是风险

毫无疑问，electron 框架的这种特性给我们平常的开发调试乃至生产环境上在某些用户的设备环境上的实机问题排查提供了相当的便利。但毕竟 js 是一门动态脚本语言，如果某个攻击者**控制了**用户的电脑，他就可以利用 electron 应用的可执行程序运行任意的代码；另外，通过启动进程的调试模式，攻击者可以通过 Node.js 的调试协议侵入程序运行的上下文，窃取或修改用户信息。

更进一步，假如用户已授予了原应用以某些特权（例如允许屏幕录制、读取通讯录、操作日历等等），那么这些特权将可以被继承给攻击者通过其实施的任何代码——这也被称为“寄生式攻击([Living off the land](https://www.crowdstrike.com/cybersecurity-101/living-off-the-land-attacks-lotl/))”。

这样看来，electron 应用存在着较大安全风险。

## 安全风险的前提

让我们关注该安全风险的发生前提，即：**攻击者已经控制了该电脑**——无论是通过对硬件的物理访问（例如多人共享使用同个计算机设备），还是通过其他的远程登录等方式。

相当一部分开发者认为这实际上并不是 electron 框架的问题，而是用户自己的问题——毕竟是用户自己管理着实际的物理设备，而应用本身只能信任当前实际持有该物理设备的用户。例如，chromium 在其安全模型中就明确声明了不考虑由本地物理攻击带来的安全问题([ref](https://chromium.googlesource.com/chromium/src/+/master/docs/security/faq.md#Why-arent-physically_local-attacks-in-Chromes-threat-model))：

> We consider these attacks outside Chrome's threat model, because there is no way for Chrome (or any application) to defend against a malicious user who has managed to log into your device as you, or who can run software with the privileges of your operating system user account. Such an attacker can modify executables and DLLs, change environment variables like PATH, change configuration files, read any data your user account owns, email it to themselves, and so on. Such an attacker has total control over your device, and nothing Chrome can do would provide a serious guarantee of defense. This problem is not special to Chrome ­— all applications must trust the physically-local user.

## 应对之道

尽管如此，electron 社区对在此前提上报告的框架安全问题依然层出不穷。例如：

- [Why electron app looking for system DLLs from the electron app installed location?](https://github.com/electron/electron/issues/28384)
- [DLL Hijacking](https://github.com/electron-userland/electron-builder/issues/3150)
- [How to avoid injecting new code into the asar archive file?](https://github.com/electron/electron/issues/19671)

此类问题持续不断，关于该风险是否应由框架层面去考虑规避（或提供规避可能）的争议也持续不断，但最终 electron 官方还是认同了框架具备为“寄生式攻击”带来可能的风险。由于使用 electron 框架的应用绝大部分都不是自行定制编译框架（那无疑是成本较高的困难做法），而是直接从官方源上下载预编译好的框架程序，从 electron v12 开始，官方在框架中设计并集成了一种“二进制保险丝”的机制，并通过 [fuses](https://www.electronjs.org/docs/latest/tutorial/fuses) 给予用户直接开启或关闭框架源生功能的能力。

其设计思路为：在构建打包时，寻找框架编译时留在可执行文件中的一段特定的二进制字节序列，进而找到并修改特定的用作功能开关的关键字节，最终实现在无需重新编译框架的前提下修改框架能力的作用。以下是一段在 `electron-builder` 中利用 `afterPack` 构建钩子以禁用框架的 `runAsNode`、`inspector`、`nodeOptions` 特性的实现样例：

```js
const path = require('path')
const { flipFuses, FuseVersion, FuseV1Options } = require('@electron/fuses')

module.exports = async function afterPack(context) {
  const ext = {
    darwin: '.app',
    win32: '.exe',
  }[context.electronPlatformName]

  const electronBinaryPath = path.join(context.appOutDir, context.packager.appInfo.productFilename + ext);

  await flipFuses(
    electronBinaryPath,
    {
      version: FuseVersion.V1,
      [FuseV1Options.RunAsNode]: false, // Disables ELECTRON_RUN_AS_NODE
      [FuseV1Options.EnableNodeOptionsEnvironmentVariable]: false, // Disable the NODE_OPTIONS environment variable
      [FuseV1Options.EnableNodeCliInspectArguments]: false, // Disables the --inspect and --inspect-brk family of CLI options
    },
  )
}
```

## 相对的安全

时至今日，electron 的版本已来到了 v29，`fuses` 控制的安全开关也多达 8 项。但实际上，也许是因为性能、便利、灵活性、实际效果等方方面面的原因，包括 `vscode`、`Notion`、`Figma`、`XMind` 等一大批 electron 应用并未使用 `fuses` 来修改框架的默认行为。从这个角度来看，`fuses` 并不算是一个成功解决方案。

让我们再思考一下：即便开发者已经在构建时通过 `fuses` 关掉了存在风险的功能开关，并不意味着框架完全不存在该风险了，攻击者同样也可以用相同的方式修改可执行程序文件，再把那些功能开关置回来。除非有一种机制，能够在应用分发到用户终端后，禁止程序资源被修改，或者是当应用被修改后，能够识别并通知用户可能的风险。

幸运的是，通过应用的数字签名(Code Signature)，无论是 Mac 还是 Windows，系统都提供了相应的校验机制([GateKeeper](https://support.apple.com/en-us/102445)/[AppLocker](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/applocker/applocker-overview))，能确保用户当前希望安装/打开的应用的所有内容都未经篡改的来自于特定的开发者，并且当应用可能存在被篡改时给予用户风险提示。例如，以下是 Mac 系统中常见的安全提示信息：

![macos gatekeeper](/img/2024-03-17/electron-security-gatekeeper.png)

不幸的是，无论是 Mac 还是 Windows，在最通常情况下，似乎都不会在**应用每次启动**时完整的校验应用签名。有鉴于此，以上 `fuses` 的安全效力，可能比实际预期要更为有限。但无论如何，electron 官方提供的解决方案很大程度上做到了框架力所能及的相对的安全。真正的安全，还是需要用户自身的关切、留意。

## References

- <https://www.electronjs.org/docs/latest/tutorial/fuses>
- <https://github.com/electron/fuses/blob/main/src/index.ts>
- <https://github.com/electron/electron/pull/24241>
- <https://www.electronjs.org/blog/statement-run-as-node-cves>
- <https://chromium.googlesource.com/chromium/src/+/master/docs/security/faq.md#Why-arent-physically_local-attacks-in-Chromes-threat-model>
- <https://github.com/electron/electron/issues/28384>
- <https://github.com/electron-userland/electron-builder/issues/3150>
- <https://github.com/electron/electron/issues/19671>
- <https://support.apple.com/en-us/102445>
- <https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/applocker/applocker-overview>
