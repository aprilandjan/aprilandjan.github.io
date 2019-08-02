---
layout: post
title:  多次调用 promise.then
link:   call-promise-then-multiple-times
date:   2019-07-05 21:34:00 +0800
categories: javascript
---

在实际业务中，可能会遇到这样的场景：已知一系列数据，需要根据这一系列数据去拉取其关联的详细内容并与原数据关联起来。例如：

```javascript
const list = [
  { user: 13, content: 'A' },
  { user: 14, content: 'B' },
  { user: 13, content: 'C' },
  ...
];
function fetchUser(userId) {
  return new Promise((resolve) => {
    fetch(`/api/user/${userId}`).then(resolve);
  });
}
list.forEach(item => {
  fetchUser(item.user).then((userInfo) => {
    item.user = userInfo
  });
});
```

上面的处理简单直接，有多少条数据就发多少个请求。可以改进一下，先对数据去重，再发请求，最后再把结果加工到原数组上，以避免发送重复的多余的请求：

```javascript
const users = _.uniqBy(list, 'user').map(item => item.user);
Promise.all(users.map(userId => fetchUser(userId)))
  .then(userInfoList => {
    list.forEach(item => {
      const userInfo = _.find(userInfoList, info => info.id === item.id);
      item.user = userInfo;
    });
  })
```

以上的方式实现起来思维上比较容易，但是有个缺点就是不得不通过 `Promise.all` 的方式等到所有请求都结束后再遍历查询更新值。因此它是互相阻塞的、慢响应的。

可以利用 `promise.then` 能够多次调用的特性创建一个批量去重加载、非阻塞的快响应方法。例如：

```javascript
// holds only necessary request promises
const map = {};
list.forEach(item => {
  let p;
  if (!map[item.user]) {
    //  if promise not cached, create it
    p = fetchUser(item.user);
    map[item.user] = p;
  } else {
    //  if promise already cached, just get reference
    p = map[item.user];
  }
  //  might called for multiple times
  p.then(userInfo => item.user = userInfo);
});
```

以上代码里，通过缓存表 `map` 存储真正需要创建的 `promise` 对象，这样当遍历列表遇到重复的情形时，直接使用已有的 `promise` 并调用 `then` 方法得到该 `promise` 的 `resolve` 值。这样既做到了去重，又做到了非互相阻塞的快响应，可以算是最优化的方案了。

这种重复调用 `promise.then` 是否是符合规范的呢？参考 [Promises/A+](https://promisesaplus.com/#point-36) 规范说明：

> then may be called multiple times on the same promise.
> If/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then.
> If/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then.

因此，这种做法是有效且可靠的。当遇到类似的场景时，会显得非常有用。
