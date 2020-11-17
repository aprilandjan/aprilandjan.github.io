---
layout: post
title:  Try Catch Finally in JS
link: try-catch-finally-in-js
date:   2020-10-19 19:19:00 +0800
categories: javascript
---

在 `javascript` 中，`try` `catch` `finally` 是用来捕获错误的关键字组合。在实际使用时，它们的组合使用方式可能会影响代码的执行顺序。在这篇文章中，我们会讨论几种令人困惑的模式，以更好的理解这些关键字，避免不当使用。

## `return` before `finally`

```js
function foo() {
  try {
    return 'foo returns';
  } catch (e) {
    //  ignore
  } finally {
    console.log('foo completed');
  }
}

function bar() {
  console.log(foo());
  console.log('bar completed')
}

bar();
```

这段代码令人困惑的点在于 `finally` 代码块与 `try` 代码块的执行先后顺序的问题。按照通常的理解，`try` 代码块先执行，则函数已 `return`，调用栈已弹出，给到上层调用的下一语句，此时又怎么可能回到该函数内去执行其 `finally` 代码块呢？

实际运行该代码，结果如下：

```bash
foo completed
foo returns
bar completed
```

可以看到，`finally` 代码块先于 `try` 代码块中的 `return` 执行了。这说明 `finally` 有一个有趣的特点：它的确**总是执行**的，但是执行时机不是等待 `try` `catch` 代码块执行完再执行，而是在 `try` `catch` 代码块**退出（`return` 也是对代码块的退出）之前**总是执行。

既然有这个区别，那么以下一些令人困惑的代码的执行结果也就都可以令人理解了：

```js
function foo() {
  try {
    return true;
  } finally {
    return false;
  }
}
foo(); // return `false` because finally returns first

function bar() {
  let i = 0;
  try {
    console.log('try', i);
    return ++i; //  just before this returns, the result value `1` is recorded(as a copy because it is a number rather than reference), and function goes into `finally` block to modify i again
  } finally {
    console.log('finally', i);
    ++i;
    console.log('finally', i);
  }
}
bar();  //  outputs `try 0` `finally 1` `finally 2` and returns 1
```

## `try` `finally` without `catch`

```js
function foo() {
  try {
    throw new Error('exception in try');
  } finally {
    throw new Error('exception in finally');
  }
}
function bar() {
  try {
    foo();
  } catch (e) {
    console.log('caught error in foo():', e.message);
  }
}
bar();
```

函数 `foo()` 没有 `catch` 代码块，当 `try` 代码块内发生错误时，错误会被抛出或者被上层的函数调用所捕获吗？直觉告诉我这里只是写法上省略了 `catch`，相当于有一个空的 `catch` 所以错误不会被抛出。执行结果如下：

```bash
caught error in foo(): exception in finally
```

可以看到， `finally` 语句中抛出的错误优先执行，符合上例的认知；没有写 `catch` 并不意味着错误可以被默认吞掉，而是**正常的抛出**，因此外层依然可以捕获到该错误。

## `catch` while `finally` throws error

```js
function foo() {
  try {
    return true;
  } catch (e) {
    console.log('caught error:', e);
  } finally {
    throw new Error('exception in finally');
  }
}
foo();
```

该函数使用了完整的 `try` `catch` `finally`，毫无疑问，`catch` 是能捕获 `try` 代码块中的异常的。但是如果在 `finally` 的代码里块发生了异常，按照上面所说的 `finally` 执行时机的问题，`catch` 能否捕获到呢？执行结果如下：

```bash
Uncaught Error: exception in finally
  at foo (<anonymous>:8:11)
  at <anonymous>:11:1
```

可以看到，`catch` 并没有能捕获到 `finally` 中的异常。原来，`catch` 只能捕获 `try` 代码块中的异常，即便 `finally` 的执行时机在 `try` `catch` 代码块退出之前，也无法捕获到。

和 `finally` 类似，`catch` 代码块中发生的错误也会被抛出到上层：

```js
function foo() {
  try {
    throw new Error('a');
  } catch (e) {
    console.log('caught error:', e);
    throw new Error('b');
  }
}
foo();  //  outputs: 'caught error: Error: a', 'Uncaught Error: b'
```

## `try` `return await` in `async` functions

在异步函数的场景下进行错误捕获，可能情况会更加复杂。例如：

```js
function tick(ok) {
  return ok ? Promise.resolve('ok') : Promise.reject(new Error('fail'));
}

async function foo() {
  try {
    return tick(false);
  } catch (e) {
    console.log('foo caught error:', e);
  }
}

async function bar() {
  try {
    const r = await foo();
    console.log('bar result', r);
  } catch (e) {
    console.log('bar caught error:', e);
  }
}
bar();  //  bar caught error: Error: fail
```

以上代码中的异步函数 `foo` 返回了一个失败的 `promise` 对象给到另外一个异步函数 `bar` 的上下文并执行结果等待 `await`，那么被 `bar` 的 `catch` 所捕获是理所当然的事情了。但是如果是以下这种场景：

```js
function tick(ok) {
  return ok ? Promise.resolve('ok') : Promise.reject(new Error('fail'));
}

async function foo() {
  try {
    return await tick(false); //  add 'await'
  } catch (e) {
    console.log('foo caught error:', e);
  }
}

async function bar() {
  try {
    const r = await foo();
    console.log('bar result', r);
  } catch (e) {
    console.log('bar caught error:', e);
  }
}
bar();  //  foo caught error: Error: fail
```

那么异常将被 `foo` 中的 `catch` 所捕获到（并且被吞掉），`bar` 拿到的 `foo()` 的执行结果为 `undefined`. 由此我们可以发现，异步函数中的 `return await PromiseObj` 以及 `return PromiseObj` 并不能一概而论的做等价转化，在 `try` `catch` 时还是应该具体分析代码的执行顺序以决定如何使用。

## references

- <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/try...catch>
- <https://stackoverflow.com/a/3838130/6817126>
