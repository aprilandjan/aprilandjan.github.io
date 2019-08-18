---
layout: post
title:  类型与类型检查
link:   type-and-type-checking
date:   2019-08-18 21:15:00 +0800
categories: typescript javascript
---

在编程语言里，”类型“ 通常用来描述某个变量持有的数据结构或特征。

## 强类型与弱类型

JavaScript 是一种弱类型的语言。所谓的“弱类型”意即不需要对变量指明它到底被用来存储着什么种类的数据。当给变量赋值时，JavaScript 会自动的根据赋予的值的信息决定变量的类型。许多语言，例如 Java，要求变量在声明时显式的指示出它持有数据的种类，并在变量后续的使用中确保类型及其方法或属性被正确使用——这些语言被称为是“强类型”的。

## JavaScript 的类型缺陷

我们知道，JavaScript 的数据类型能大致分为以下两类：

- 原始数据类型 (primitives)：包括 `boolean` `number` `string` `null` `undefined` 以及 ES6 中新引进的 `Symbol` 等；
- 对象类型（Objects)：包括 `object` `array` `function` 等。

通常，可以用 [typeof](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/typeof) 运算符在**运行时**获得某个值的类型。但是由于历史原因，该运算符对某些值的结果会令人匪夷所依，例如：

- `typeof null` 得到的结果不是 `null` 而是 `object`；
- `typeof [1, 2, 3]` 得到的是 `object` 而不是 `array`；
- `typeof () => {}` 得到的是 `function` 而不是 `object`。

总之，为了确保某些变量在**运行时(runtime)**的类型符合预期（从而使用该类型的特殊属性或方法），开发者总是不得不采用各种合适的判断方法去加以保障；一旦某些判断不完全或缺失，在实际执行时即有可能造成意外的错误发生。这也是由于源生 JavaScript 对类型的描述能力非常孱弱且实际的类型的判断约束仅仅发生在**运行时**的缘故。

## 扩展类型描述

为了增强 JavaScript 对类型的描述和约束能力，并尽可能的把运行时的类型判断和检查提前到开发代码的**编译时(compile-time)**从而提早避免意外错误发生，开源社区以其他强类型语言为蓝本，逐渐推出了一些行之有效的解决方案。它们通过对 JavaScript 的语法进行加工，补上特殊的类型描述符和声明语句，并通过分析代码语法树实现一定程度的类型合理性推导及校验。

目前获得社区认可的类型扩展及检查方案包含两种：

- [TypeScript](http://www.typescriptlang.org/)：由 Microsoft 发起并推广的 `JavaScript` 语言超集。使用最为广泛，开源生态良好。
- [Flow](https://flow.org/)：由 Facebook 开源的静态类型检查工具。较小众，没有或无法构建类型生态，相比前者缺乏竞争力。

由于 TypeScript 经过几年的发展已逐渐成为了目前 JavaScript 语言的类型扩展的事实标准，因此后文的内容主要围绕它来展开阐述。

## 使用 TypeScript

TypeScript 是“带有类型的 JavaScript 的语言超集”。所谓超集，意即在支持源生 JavaScript 的全部语法特性的基础上，还额外带有类型声明及定义、类型推导和检查等功能。通过 TypeScript 提供的 **编译器(TypeScript Compiler)**，可以把 TypeScript 代码文件 `(.ts)` 编译转换为 `(.js)` 文件；在转换过程中，类型检查将发挥作用，检查类型是否符合约束，避免运行时的潜在错误。

以下罗列使用 TypeScript 的一些关键知识点，具体可以参看文末的参考链接：

- 类型声明
  - 基础类型(basic)
    - primitives
    - object
    - any/void
  - 接口(interface)
    - 键值类型匹配及描述
    - 属性修饰符
    - 函数类型声明
    - 索引类型
    - 类型扩展继承
    - 类型合并
  - 泛型(generic)
- 开发配置
  - 安装 `typescript` 模块
  - 结合 `webpack` 使用
  - 结合 `babel` 使用
  - 结合 `eslint` 使用
  - 结合 `React` 使用
- 模块生态
  - 声明文件 `.d.ts`
  - `@types/<name>` 类型声明模块
  - 编辑器支持: LSP & Lint

## 参考链接

- [TypeScript 官网](https://www.typescriptlang.org/index.html): 官方站点，提供 TS 各种语法的说明及示例、`tsc` 配置项说明、Playgrond 等；
- [TypeScript Book](https://github.com/basarat/typescript-book/): 社区总结的 TS 指导书，相比官方文档更加偏向实践；
- [TypeScript React Redux Guide](https://github.com/piotrwitek/react-redux-typescript-guide): TS 在 React 生态开发使用的最佳实践的说明。
