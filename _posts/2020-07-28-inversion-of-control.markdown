---
layout: post
title:  Inverse of Control
link: inverse-of-control
date:   2020-07-28 21:22:00 +0800
categories: coding
---

控制反转（Inverse of Control, IoC）是一个听起来很令人困惑的的编程术语。它表达的含义是什么，在实际编程中有哪些应用场景，能够解决什么样的问题，恐怕很多经验丰富的开发者也很难说的清楚。在此，我将按照自己的理解，尝试对它进行解读。

## CLI & GUI

先从一个简单的上手。在某个命令行（CLI） 程序里，我们可能会这样实现一个存储用户信息的功能：

```
print "enter your name"
read name
print "enter your address"
read address
...
store in database
```

以上程序的整个控制流程是根据代码的先后顺序确定的：什么时候`输出提示`，什么时候`读取内容`，什么时候`存储数据`。但是如果在一个图形界面（GUI）程序里，我们可能会这样实现：

```
when user type in field a, store the value in NAME
when user type in field b, store the value in ADDRESS
when user click the save button, store NAME and ADDRESS in database
```

在这种情况下，程序的控制流程发生了变化：什么时候`读取内容`、`存储数据`，执行的时机发生了变化。在命令行程序里，是我们（编码者的业务代码）控制这些方法调用，而在图形界面程序里，我们并没有控制这些方法调用，而是交给了程序框架的事件循环机制，它根据我们绑定的事件，决定了什么时候去调用流程方法。因此，程序的控制流程发生了反转：是框架去调用执行我们的控制流程，而不是我们去调用执行控制流程。这种模式可称之为控制反转。

## `Don't call us, we'll call you`

控制反转也常常和好莱坞原则（Hollywood Principle）出现在一起：

> Don't call us, we'll call you

大意即：不要自己去好莱坞实现理想；如果你有价值，好莱坞回找到你并且让你梦想成真的。听起来的确有一些“反转”的意思在其中。

在实际编码中，控制反转也是`框架(Frameworks)`与`库(Library)`的一个关键差别所在。`库`通常是一系列应用代码里可以直接调用的方法或类，每次调用执行，传递一些上下文，并将控制流程返回应用代码；而`框架`是一些包含更多内置行为的抽象设计的具体化表达，为了使用`框架`，需要将我们的行为通过子类、钩子方法或者插件的机制注入到框架的不同地方，`框架`内置的代码会在合适的时机去执行我们的代码。

> One important characteristic of a framework is that the methods defined by the user to tailor the framework will often be called from within the framework itself, rather than from the user's application code. The framework often plays the role of the main program in coordinating and sequencing application activity. This inversion of control gives frameworks the power to serve as extensible skeletons. The methods supplied by the user tailor the generic algorithms defined in the framework for a particular application.

-- [Design Reusable Classes, by Ralph Johnson and Brian Foote](http://www.laputan.org/drc/drc.html)

## 总结

拿前端开发举例来说，相较于面向业务流程编程（即自己按业务流程顺序依次实现每个控制流程），Express/Koa 这种`框架`提供了中间件机制，`node.js` 提供了事件循环、回调机制，`EventEmitter` 实现了事件发布订阅机制，React/Vue 这种`框架`提供了基类组件、生命周期等机制。这些都可以认为是控制反转的表现。所以，最终的结论就很显而易见了：与其创造一个自己控制所有流程的应用程序，不如通过（使用甚至创造）可复用的`框架`去控制应用的抽象设计，再增加自己的业务代码，恰当的注入（挂载）到框架中，由框架在合适的业务时机调度执行。

## References

- <https://stackoverflow.com/questions/3058/what-is-inversion-of-control>
- <https://martinfowler.com/bliki/InversionOfControl.html>
