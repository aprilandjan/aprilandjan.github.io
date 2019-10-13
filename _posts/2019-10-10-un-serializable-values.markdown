---
layout: post
title:  不可序列化的值
link:   un-serializable-values
date:   2019-10-10 21:20:00 +0800
categories: javascript
---

最近有用户给我之前写的用于生成目录树的 `vscode` 插件 [ascii-tree-generator](https://github.com/aprilandjan/ascii-tree-generator) 提 [issue](https://github.com/aprilandjan/ascii-tree-generator/issues/2)，反馈某个功能没有响应。在定位调试该问题的过程中，发现一个奇怪的情况：

在本地调试插件源码时，`vscode` 任务会唤起一个单独的安装了该插件的窗口，并且把在该窗口中的插件的调试信息发送到宿主调试控制台中。当通过 `console.log` 打印某个实际值为 `Infinity` 的变量的值的时候，宿主调试控制台却显示为 `null`。但是通过断点查看该值实际上的确是 `Infinity` 无疑。

难道是 `vscode` 的插件调试程序对某些值的打印显示不正确吗？从 `vscode` 的插件模板生成工具生成了一份空白项目测试了一下，该问题依然存在。搜了下相关 issue 没有找到类似信息，于是给 `vscode` 提了一个 [issue](https://github.com/microsoft/vscode/issues/82104#event-2698545870) 反馈。

很快 `vscode` 开发者确认了该问题存在，并指出了可能的原因：

> This is probably due to "infinity" not being JSON serializable:
> ```javascript
> JSON.stringify({x: Infinity})
> "{"x":null}"
> ```

## 不可序列化的值

原来，当使用 JSON 序列化对象时，诸如 `Infinity`, `-Infinity`, `NaN` 这些**特别的**的值会被处理为 `null`。原因很容易理解：JSON 是一种跨越不同编程语言的序列化数据的格式，而 `Infinity` `NaN` 这些在 JS 中有特殊意义的值，并不能在 JSON 序列化或反序列化时能保证其意义相同或是稳定的。而倘若无法保证其简单、可靠、稳定的数据传递，那就难以在各个语言中通用、形成标准。因此，JSON 这样直接“过滤”掉这些非标准的值，也情有可缘了。

## 进程间通信的值传递

回到上面的问题上来。为什么这个 `vscode` 宿主调试控制台的输出会和 JSON 的序列化有关系呢？可能是因为在插件调试程序的模式中，实际发生 `console.log` 的程序窗口的输出信息是通过进程间通信的方式传递到宿主调试控制台中并显示的。而一般的进程间通信传递的信息是字符串，因此通常使用 JSON 对传递的信息做序列化传输和反序列化释意。可以想见，此处 `vscode` 的宿主调试器应该就是接收到了通过 JSON 传输的信息，导致 `Infinity` 这种值被错误的显示为 `null`。

无论如何，这依然是一个调试程序显示上的 bug。如果能正确的显示出实际的值内容，应该会比较友好，避免类似的困惑发生。

## JSON5

那有没有办法能使得 JSON 支持这种值的序列化与反序列化呢？答案是肯定的。正如 JS 拥有若干超集语言如 `es`, `ts` 一样，JSON 也拥有超集工具 [JSON5](https://github.com/json5/json5)。`JSON5` 拓展了 JSON 的语法能力，减少了 JSON 的许多局限，例如注释、单引号、换行符、行尾逗号、Infinity/NaN 等等：

```json5
{
  // comments
  unquoted: 'and you can quote me on that',
  singleQuotes: 'I can use "double quotes" here',
  lineBreaks: "Look, Mom! \
No \\n's!",
  hexadecimal: 0xdecaf,
  leadingDecimalPoint: .8675309, andTrailing: 8675309.,
  positiveSign: +1,
  trailingComma: 'in objects', andIn: ['arrays',],
  "backwardsCompatible": "with JSON",
}
```

假如有必要，可以考虑使用它来做数据的序列化与反序列化，或许可以解决某些特定场景的问题。

## 参考

- <https://github.com/microsoft/vscode/issues/82104#event-2698545870>
- <https://stackoverflow.com/questions/1423081/json-left-out-infinity-and-nan-json-status-in-ecmascript>
