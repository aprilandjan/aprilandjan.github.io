---
layout: post
title:  async 转换为 sync
link:   turn-async-into-sync
date:   2019-12-13 21:14:00 +0800
categories: javascript
---

编写一段异步代码总是很容易的。以下是一些可能的方式方法：

```js
// 1. callback
function wait(t, callback) {
  setTimeout(() => {
    callback(t);
  }, t);
}
wait(1000, (t) => {
  console.log('time passed', t);
})

//  2. promise
function wait(t) {
  return new Promise((resolve) => setTimeout(() => resolve(t), t));
}
wait(1000).then(t => {
  console.log('time passed', t)
})

//  3.  generator
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

//  4. async await
function wait(t) {
  await new Promise(resolve => setTimeout(resolve, t));
  return t;
}
(async () => {
  const t = await wait(1000);
  console.log('time passed', t);
})();
```

那么，如何将一段异步代码转换为同步？首先想到的是利用 `while` 循环去填充 js 执行，达到在启动某个`'异步'`任务后阻塞其他代码执行的效果：

```js
function wait (t) {
  return new Promise(resolve => setTimeout(resolve, t));
}

function test(p) {
  let resolved = false;
  p.finally(() => {
    console.log('async done');
    resolved = true;
  })
  while(!resolved) {
    // do nothing
  }
}

(() => {
  console.log('a');
  test(wait(1000));
  console.log('b')
})();
```

这段代码执行后并没有希望中的按顺序输出 `a` `async done` `b`，而是在打印出字符 `a` 之后程序一直停留在 `while(!resolved)` 的循环内执行下去，不会结束，也不会打印出 `async done`。这说明 `while(true)` 语句的却是阻塞了其他的代码——也包括它前面的 `p.finally`。其实也很符合逻辑：假如它不能阻塞前面 `Promise` 的执行，那就肯定也无法阻塞其他的代码块执行了。既然这样，那类似 `nodejs` 里的 `fs.writeFileSync` 以及 `fs.writeFile` 它们是如何能做到既能同步又能异步的呢？

## 事件循环
