---
layout: post
title:  使用 generator 模拟 async
link:   use-generator-to-make-async
date:   2019-12-20 22:15:00 +0800
categories: javascript
---

在之前的文章 《async 转换为 sync》 中，提到了几种编写异步代码的模式，其中就有使用 generator 实现的例子：

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