---
layout: post
title:  不可序列化的值
link:   un-serializable-values
date:   2019-10-10 21:20:00 +0800
categories: javascript
---

最近有用户给我之前写的用于生成目录树的 vscode 插件 [ascii-tree-generator](https://github.com/aprilandjan/ascii-tree-generator) 提 issue，反馈某个功能没有响应。在定位调试该问题的过程中，发现一个奇怪的情况。在本地调试插件源码时，vscode 任务会唤起另一个单独的窗口，并且把在该窗口中的操作正确的中断并反馈到当前源码窗口的调试界面中。

## 可序列化的值

## 不可序列化的值

## 进程间通信的值传递

## JSON5

## 参考

- <https://github.com/microsoft/vscode/issues/82104#event-2698545870>
