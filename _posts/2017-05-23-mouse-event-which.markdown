---
layout: post
title:  mouse event which
date:   2017-05-23 21:21:00 +0800
categories: javascript
---

在开发 `nw` 上的某个页面时，遇到了这么一个问题：

页面里某个元素需要用 js 写拖拽移动操作，一般的做法是通过 `mousedown` `mousemove` `mouseup` 来做拖拽模拟，这一部分也是能够正常工作的；但是，给这个元素同时加上 `contextmenu` 事件并唤起右键菜单时，会发生冲突：因为触发 `contextmenu` 事件的实际操作行为是在元素上点击鼠标右键，而鼠标右键也能触发 `mousedown` 事件，导致了预期之外的拖拽开始。

能否使得 `contextmenu` 触发的时候不触发 `mousedown` 呢？尝试了各种方式，仿佛都没有办法让这两个事件直接的阻止彼此的触发行为。突然想到，如果能知道触发 `mousedown` 的来源是否是右键，不就能阻止干扰了吗？查了一下资料，果然还是有这种属性的, 那就是 [`MouseEvent.which`](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/which):

MouseEvent.which 指代了当事件触发的时候，是哪一个按钮被按下了。虽然这个特性并非是标准里所规定的，但是似乎各浏览器厂商很早就已实现了。

以下是各个值的说明：

- 0: 没有按键
- 1: 左键
- 2: 中键
- 3: 右键

有了这个属性，那么以上遇到的问题就可以解决了。只需简单的在 `mousedown` 触发的时候判断 `event.which` 是否为 `3`，如果是，`return` 掉即可。


