---
layout: post
title:  new without parentheses
date:   2017-04-10 11:06:00 +0800
categories: javascript
---

看 `koa` 示例的时候，发现创建新日期对象可以这么写：

```javascript
var start = new Date;
```

尝试了一下，以上写法在 chrome 里是正确的。

通常使用 `new` 关键字调用构造函数，都会带上一对括号(parentheses), 那么这种不带括号的使用方法有没有什么标准说明呢？万能的 MDN 上给出了[说明](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/new)：

> The constructor function Foo is called with the specified arguments, and with this bound to the newly created object. new Foo is equivalent to new Foo(), i.e. if no argument list is specified, Foo is called without arguments.

翻译一下，即：构造函数 `Foo` 调用时可以附加上特定的参数，通过这种方式把参数传递给新创建的对象。`new Foo` 等同于 `new Foo()`, 也就是说，如果没有定义参数列表，`Foo` 被调用时也不用传参。 