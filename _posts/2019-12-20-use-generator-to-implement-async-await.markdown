---
layout: post
title:  使用 generator 实现 async await
link:   use-generator-to-implement-async-await
date:   2019-12-20 22:15:00 +0800
categories: javascript
---

在之前的文章 `《async 转换为 sync》` 中，提到了几种编写异步代码的模式，其中就有使用 generator 实现的例子：

```javascript
function *wait(t) {
  const r = yield new Promise(resolve => setTimeout(() => {
      resolve(t);
  }, t));
  return r;
}
((gen) => {
  const g = gen(1000);
  function run (arg) {
    const result = g.next(arg);
    if (result.done) {
      return result.value;
    } else {
        //  wait until promise resolve
      return Promise.resolve(result.value).then(run);
    }
  }
  return run();
})(wait).then(t => {
  console.log('time passed', t);
});
```

在充分理解这段代码之前，我们需要对其中涉及到的生成器 `generator` 的概念有一定的理解。

## 生成器 generator

生成器是一种使用关键字 `*` 作为标注的函数。在生成器被调用后，其函数内部的方法并不会被立即开始调用执行，而是会返回一个可迭代的**生成器对象**。当调用该生成器对象的 `next` 方法时，生成器函数才会往下执行，直到遇到以关键字 `yield` 标注的语句；继续调用`next` 方法可以使生成器的逻辑继续执行到下一个 `yield`  语句，直到生成器函数全部执行完毕。

每次调用该可迭代对象的 `next` 方法均会返回表征当前迭代状态的对象 `{value, done }`。其中 `value` 是对应的 `yield` 所“返回”的值，`done` 是指示该生成器对象是否已迭代完毕的布尔值。

以下是一个生成器的简单示例：

```javascript
function * makeOutputJob() {
  yield 1;
  yield 2;
  yield 3;
}

const job = makeOutputJob();
console.log(job.next());  //  {value: 1, done: false }
console.log(job.next());  //  {value: 2, done: false }
console.log(job.next());  //  {value: 3, done: false }
console.log(job.next());  //  {value: undefined, done: true }
```

生成器函数也能添加自定义参数，例如：

```javascript
function * makeOutputJob(start) {
  yield start;
  yield start + 2;
}

const jobFrom2 = makeOutputJob(2);
console.log(jobFrom2.next());  //  {value: 2, done: false }
console.log(jobFrom2.next());  //  {value: 4, done: false }
console.log(jobFrom2.next());  //  {value: s, done: true }

const jobFrom3 = makeOutputJob(3);
console.log(jobFrom3.next());  //  {value: 3, done: false }
console.log(jobFrom3.next());  //  {value: 5, done: false }
console.log(jobFrom3.next());  //  {value: undefined, done: true }
```

在调用生成器对象的 `next` 方法时也可以传值，并给到下一个 `yield` （而不是 `yield` 之后的语句的执行结果）。例如：

```javascript
function * makeOutputJob(start) {
  const a = yield start;
  const b = yield start + a;
  return b;
}

const job = makeOutputJob(100);
console.log(job.next(3)); //  {value: 100, done: false }. The first next(value) is always ignored. 'a' is undefined now.
console.log(job.next(5)); //  {value: 105, done: false }. 'a' got its value as '5' and returned value as 100 + 5 = 105. 'b' is still undefined now.
console.log(job.next(10));  // { value: 10, done: true }. 'b' got its value as '10' rather than '105'.
```

可以看到这里 `yield` 其实相当特别。可以认为它是一个代表着来自下一个 `next` 操执行时传递参数的动态变量，和它之后的语句执行结果没有任何关系。`yield` 之后的语句只影响对应的 `next` 输出的结果 `value`。这和使用 `async await` 语法去写异步函数的认知是完全不同的。例如：

```javascript
//  此处先忽略 await 后面的语句是否能返回 promise
(async function job(start) {
  const a = await start;  //  start = 100, a = 100
  const b = await start + a;  //   start + a = 200, b = 200
  return b; //  b = 200
})(100)
```

也可以在生成器内部使用 `yield*` 指向某个迭代器对象，包括数组、字符串，甚至是另外的一个生成器对象，例如：

```javascript
function* makeOutput() {
  yield 'a';
  yield 'b';
}

function * makeOutputJob() {
  yield [1, 2];
  yield* [3, 4];
  yield '56';
  yield* '78';
  yield* makeOutput();
}

const job = makeOutputJob();
let result;

do {
  result = job.next();
  console.log(result);
} while (!result.done)
```

值得一提的是，生成器所生成的“可迭的生成器对象”实际上就是一个 `迭代器(Iterator)` 对象，`yield*` 会将当前生成器的执行委托到其后的迭代器对象中进行。

## 实现 `async-await` 形式的调用

掌握了生成器的工作原理，结合 `Promise`，我们可以实现一个符合 `async await` 使用习惯的实现。考虑以下异步调用：

```javascript
function wait (t) {
  return new Promise((resolve) => setTimeout(() => {
    resolve(t * 2);
  }, t));
}

async function exec(t) {
  console.log(t);
  const a = await wait(t);
  console.log(a);
  const b = await wait(a);
  console.log(b);
  return b;
}
exec(100);  //  output 100, 200, 400 in sequence
```

现使用生成器去实现，首先使用形态上调整为类似的结构：

```javascript
function* exec(t) {
  console.log(t);
  const a = yield wait(t);
  console.log(a);
  const b = yield wait(a);
  console.log(b);
  return b;
}
```

但并不是这样就可以直接调用就可以使用了，还需要针对 `Promise` 以及 `yield` 的特殊性做一些加工，使得可以正确等待 `Promise.resolve` 的状态以及 `yield` 值传递：

```javascript
function runAsync(gen) {
  return new Promise(resolve => {
    function next(arg) {
      const result = gen.next(arg);
      if (result.done) {
        resolve(result.value);
      } else {
        //  如果该步骤执行结果是一个 Promise, 等待其执行完毕并将结果传递到生成器对象内
        //  此处使用了 `Promise.resolve` 能够接受另外一个 Promise 对象的特性
        return Promise.resolve(result.value).then(next)
      }
    }
    next();
  });
}
runAsync(exec(100));
```

以上方法稍加改进，利用 `next()` 的返回值即可优化为本文顶部描述的实现。这也是 `babel` 等转换器转换 `async await` 为 `Promise` 的大致步骤——当然，还需要对 `generator` 语法的转换。

## 参考

- <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Iterators_and_Generators>
- <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*>
- <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/yield*>
- <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve>
