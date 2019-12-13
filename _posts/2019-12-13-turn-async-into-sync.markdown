---
layout: post
title:  async 转换为 sync
link:   turn-async-into-sync
date:   2019-12-13 21:14:00 +0800
categories: javascript
---

如何将一段异步代码转换为同步？

```js
function wait (t) {
  return new Promise(resolve => setTimeout(resolve, t));
}

function test(p) {
  let resolved = false;
  p.finally(() => {
    console.log('resolved....');
    resolved = true;
  })
  while(!resolved) {
    // do nothing
    // require('deasync').sleep(100);
  }
}

(() => {
  console.log('a');
  test(wait(1000));
  console.log('b')
})()
```
