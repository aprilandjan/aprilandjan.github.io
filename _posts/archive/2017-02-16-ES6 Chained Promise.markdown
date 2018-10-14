---
layout: post
title:  ES6 Chained Promise
date:   2017-02-16 16:47:00 +0800
categories: javascript
---

Babel 实现的 Promise 串联起来使用 (`chain-calling`) 很简答，在调用 `then(resolve)` 方法的时候，`resolve` 函数返回一个 promise 即可。

代码如下:

```javascript
function wait (time) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      console.log(`wait ${time} complete...`)
      resolve(time * 2)
    }, time)
  })
}

wait(500).then(t => {
  return wait(t)
}).then(t => {
  return wait(t)
}).then(t => {
  console.log('STOP...')
})
``` 