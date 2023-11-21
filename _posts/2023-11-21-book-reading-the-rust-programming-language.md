---
layout: post
title: 读书感悟：《rust 程序编程语言》
link: book-reading-the-rust-programming-language
date:   2023-11-21 22:58:00 +0800
categories: rust
---

## 临时变量命名困难症

在 js 代码中，经常会遇到需要在作用域中对参数做多轮临时处理的情况，难免会遭遇起名困难：

```ts
function formatList(rawList) {
  const processedList = filterEmpty(rawList);
  const groupList = groupListByType(processedList, 'some-type');
  const neededList =  filterNeeded(groupList);
  // ...
  return [...];
}
```

其中，`processedList` `groupList` `neededList` 等等只是一串中间处理过程，本身没有太多实际意义。rust 中，变量具有 [隐藏(shadowing)](https://doc.rust-lang.org/stable/book/ch03-01-variables-and-mutability.html#shadowing) 特性，支持在同一个作用域内多次使用同一个变量名，即新变量的声明可以覆盖掉旧的同名变量：

```rs
fn main() {
  let x = 5; // x 并非 mut 变量，相当于 js 的 const
  let x = x + 1;
  let x = String::new("hello, world");  // 甚至可以变成其他类型
}
```

看起来非常实用，很多时候直接可以单个名字一把梭，再也不用担心怎么为起不一样的名字了。也许，这可能得益于其变量默认 immutable 的设计理念。

## 争论语句结束要不要加分号

在 rust 里，很可能需要关注[函数体中的语句(Statement)与表达式(expression)](https://doc.rust-lang.org/book/ch03-03-how-functions-work.html#statements-and-expressions)。语句指那些执行操作、但不返回值的指令，而表达式是指会进行计算、并最终产生一个值作为结果的指令。但，如果我们给表达式结尾添加分号“;”, 其就会变成语句，而不产生任何值：

```rust
fn add1(v: i32): i32 {
  v + 1
}

fn add2(v: i32): i32 {
  v + 2;
}
```

以上两个函数，前者会将最后一句 `v + 1` 表达式的值作为函数返回值，而后者会发生编译错误，因为它具有分号，变成了语句，不能满足函数签名。

这也是一点 rust 和 js 有很大差异的点，从语法规范上就杜绝了语句结束“加不加分号”的争论。这个省掉一个 return 语句的操作，很难说它好还是不好，只能说更加精细化了。

## 鸭子类型

对于 TS 来说，一个很显著的特性就是我们可以定义两个不同名的类型，只要它们的满足彼此约束，就可以当成另外一个类型使用，即：有一个东西，它长得像鸭子，叫的像鸭子，会游泳，那它就可以认为是鸭子。

```ts
interface Duck {
  name: string;
  swim () {};
}

function letDuckSwim(duck: Duck) {
  duck.swim();
}

interface Something {
  name: string;
  swim () {};
}

const sm: Something = {
  name: 'some strange thing',
  swim () {
    console.log('swimming now!');
  }
}

letDuckSwim(sm);
// output: swimming now!;
```

[结构相同的非同名结构体](https://doc.rust-lang.org/book/ch05-01-defining-structs.html#using-tuple-structs-without-named-fields-to-create-different-types)

## References

- <https://doc.rust-lang.org/stable/book/title-page.html>
