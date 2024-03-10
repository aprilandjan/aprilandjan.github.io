---
layout: post
title: 浅谈 chromium 的定时器限流策略
link: chromium-timer-throttling-strategy
date:   2024-03-10 17:56:00 +0800
categories: js
---

使用 web 技术栈开发的应用，往往需要使用定时器实现一些轮询或定时更新之类的操作。也许你思考过，倘若放任页面自身的定时任务自由运行，是否会对用户的系统资源消耗产生不可忽略的开销。事实上，chromium 内核的确具有对 js 定时器的触发限流策略，这些策略或多或少的会对应用本身的运行时序有不容忽视的影响。在此，我们简单的了解下相关机制，以帮助更好的组织、实现页面功能。

## 连锁定时器(Chained Timer)

所谓“连锁定时器”，指的是在某个定时任务回调中触发的下一个定时器。根据这个概念，`setInterval` 将总是被认为是连锁定时器，其连锁次数由其触发次数决定。以下是使用 `setInterval`、`setTimeout` 且被认定为连锁定时器的例子：

```js
let chainCount = 0;

setInterval(() => {
  chainCount++;
  console.log(`This is number ${chainCount} in the chain`);
}, 500);
```

```js
let chainCount = 0;

function setTimeoutChain() {
  setTimeout(() => {
    chainCount++;
    console.log(`This is number ${chainCount} in the chain`);
    setTimeoutChain();
  }, 500);
}
```

## 最小间隔限流

当满足以下**任意一种**条件时，浏览器将对页面定时器进行**最小间隔限流**：

1. 页面可见；
2. 页面在最近 30 秒内有播放出声音。

其限制方式为：如果定时器延迟时间如果小于 4ms，且当前的连锁执行次数 >= 5，则将定时器的触发最小间隔设置为 4ms。可以在页面中快速测试一下：

```js
let p = performance.now();
setInterval(() => {
  let t = performance.now() - p;
  p = performance.now();
  console.log(t);
}, 1);
```

上例中，我们采用 `performance.now()` 获取高精度时间，便于观察精确的触发间隔。定时器应该以 1ms 的间隔运行，并打印出离上一次运行的时间间隔。运行结果如下：

![minimal throttling](/img/2024-03-10/chromium-timer-throttling-minimal.png)

定时器的前 4 次触发基本都是接近 1ms；从第 5 次开始，触发间隔被限制为接近 4ms。结合该策略的触发条件，几乎任何激活的页面中的定时器，都会受到影响。因此可以得出结论，即：浏览器中，定时器通常无法以低于 4ms 的间隔稳定、持续运行。

## 常规限流

当定时器不处于以上提及的“最小间隔限流”策略下、且页面满足以下**任意一种**条件时，浏览器将对定时器进行**常规限流**：

1. 定时器连锁次数 < 5；
2. 页面不可见且其不可见时间不超过 5min；
3. 页面正在使用 WebRTC 进行实时流传输。

在这种情况下，浏览器将会**每秒**检查一次，并且将这一秒内的定时任务批量触发一次。同样的，我们可以通过以下一段代码在页面中简单的验证；

```js
window.addEventListener('visibilitychange', () => {
  console.log('page visible?', document.visibilityState);
});

let p = performance.now();
setInterval(() => {
  let t = performance.now() - p;
  p = performance.now();
  console.log(t);
}, 300);
```

上例中，我们通过 `visibilitychange` 监听页面可见状态的变化；稍后，我们将会以切换浏览器 Tab 的方式控制页面可见状态，并观察定时器触发频率。运行结果如下：

![regular throttling](/img/2024-03-10/chromium-timer-throttling-regular.png)

尽管我们设置的定时间隔是 300ms，但在页面不可见后，实际的触发间隔变成了 1000ms！因此，如果我们有一些小于 1s 触发间隔的定时任务，那么它们很可能在页面隐藏时变得不可靠。

## 激进限制

当定时器不处于以上的“最小间隔限流”或“常规限流”策略下、且页面满足以下**所有条件**时，浏览器将对定时器进行**激进限流**：

1. 页面已不可见超过 5min；
2. 定时器连锁次数 >= 5；
3. 页面未在使用 WebRTC 进行实时流传输。

在这种情况下，浏览器将会**每分钟**检查一次，并且将这一分钟内的所有定时任务批量触发一次。以下是一段验证代码：

```js
window.addEventListener('visibilitychange', () => {
  console.log('page visible?', document.visibilityState);
});

function startTimer(id, interval) {
  let p = performance.now();
  setInterval(() => {
    let t = performance.now() - p;
    p = performance.now();
    console.log(`${id}: ${t}ms`);
  }, interval);
}

startTimer('t1', 10_000);
startTimer('t2', 30_000);
startTimer('t3', 50_000);
```

运行结果如下：

![intensive throttling](/img/2024-03-10/chromium-timer-throttling-intensive.png)

可以看到，`t1` `t2` `t3` 这三个定时器在页面长期不可见后，集中在每分钟一次的时间点同时触发，较原定频率大大降低，同时也有可能因任务密集触发执行出现进程间歇繁忙。

## 总结

为了节省应用的资源占用，降低 CPU 使用率从而降低能耗、提高电池使用频率，chromium 针对定时器可谓是煞费苦心，设计了以上几种不同的限流触发策略。作为前端开发人员，我们可能会遇到由此带来的一系列问题，例如：基于定时器的动画或业务逻辑无法按预期节奏执行，某一批不同的定时任务总是集中在一个时间点触发、浏览器自动化测试任务出现非预期的结果，等等。

这种影响，并不仅仅出现在 Web 应用中，同样也出现在使用 chromium 内核的桌面应用中，例如 electron。由于桌面应用的长期运行特性，该限流策略带来的影响往往会放大，变得难以忍受（例如某些尝试通过轮询的场景，不能及时获取到最新消息等等）。在 electron 应用中，我们可以通过给窗口指定 `backgroundThrottling: false` 显式禁掉其的定时器限流策略，或者通过应用全局的参数设置 `--disable-background-timer-throttling` 禁掉所有窗口的该限制。当然，这样做会失去原策略带来的降低系统消耗的收益。如果确实想“既要”“又要”，那可能需要通过针对性的改造以避免连锁定时器式的实现了。

## References

- <https://kinsta.com/browser-market-share/>
- <https://developer.chrome.com/blog/timer-throttling-in-chrome-88>
- <https://www.electronjs.org/docs/latest/api/command-line#commandlineappendswitchswitch-value>
- <https://www.electronjs.org/docs/latest/api/browser-window#new-browserwindowoptions>
