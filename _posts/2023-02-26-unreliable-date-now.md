---
layout: post
title: 不可靠的 `Date.now()`
link: unreliable-date-now
date:   2023-02-26 22:00:00 +0800
categories: nodejs
---

在 JS 的世界中，获取当前时间是一件轻而易举的事。内置的 `Date.now` 函数可以在任何地方直接调用输出当前的时间戳，例如：

```ts
console.log(`current timestamp is: ${Date.now()}`); // output: current timestamp is: 1673415724435
```

通常我们也用它来做一些执行过程耗时的度量。例如，以下是一段度量 electron 应用启动速度并记录日志的代码片段：

```ts
// 记录应用第一行代码开始执行的时间
const tStart = Date.now();

// did-launch 定义为应用的第一个窗口首次渲染完毕
app.on('did-launch', () => {
  // 计算启动耗时
  const tLaunch = Date.now() - tStart;
  // 上报日志
  log.info('app-did-launch', {
    duration: tLaunch,
  });
});
```

代码看起来简单易懂，似乎无懈可击。但实际采集上来的数据却总有一些令人匪夷所思的、成千上万的秒数。应用启动可能耗费这那么久吗？显然不太可能——不要说几千秒，就算是几十秒，对于应用的启动速度来说也是很之夸张了！鉴于这种离谱的数据还不算少，有必要挖掘一下这些异常现象的来源。

唯一的疑点只能在 `Date.now()` 函数调用的返回值中了。它有可能返回一个偶尔偏离真实时间的值吗？

## 追根溯源 `Date.now()`

找到 [MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/now) 上对该方法的说明：

> The **Date.now()** static method returns the number of milliseconds elapsed since the epoch, which is defined as the midnight at the beginning of January 1, 1970, UTC.

MDN 对该方法的说明并没有什么特别，但指出其函数规范定义来自 `ECMAScript`。事实上，`Date` api 与 `node.js` 中特有的 `process` api 或者浏览器中特有的 `document` api 完全不同，它属于 `ECMAScript`(即我们经常提到的 `ES`) 语言规范的一部分，而我们所编写的 JS 正是该语言规范的一种实现。以下是规范中对该方法的[描述](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-time-values-and-time-range):

> **21.4.3.1 Date.now()**
> This function returns the time value designating the UTC date and time of the occurrence of the call to it.

规范中，仅说明了函数返回其调用时的 UTC 时间。在这个层面，它只是语言的定义，即具有哪些语法能力、内置的对象或方法的描述定义等，并不涉及到底层实现。真正负责解释执行函数调用的，即为 `Javascript Engine`；具体到 `electron` 框架中，这个引擎即为 `v8`。

![](/img/2023-02-26/date-now-v8.png)

`v8` 是一个由 Google 开源的、使用 C++ 编写的跨平台 JS 引擎，我们熟知的 `node.js`、`chrome` 都使用它解释执行 JS。而 `electron` 可以认为是一个集成了 `node.js` 的 `chrome` 浏览器。因此，想要找到应用中 `Date.now()` 底层实现的方式，就需要查找 `v8` 的源码了。一番搜索之下，找到了如下实现：

```cpp
// https://github.com/v8/v8/blob/9.4.146.24/src/base/platform/time.cc#L323
#if V8_OS_WIN

class Clock final {
 public:
  Clock() : initial_ticks_(GetSystemTicks()), initial_time_(GetSystemTime()) {}

  Time Now() {
    // Time between resampling the un-granular clock for this API (1 minute).
    const TimeDelta kMaxElapsedTime = TimeDelta::FromMinutes(1);

    MutexGuard lock_guard(&mutex_);

    // Determine current time and ticks.
    TimeTicks ticks = GetSystemTicks();
    Time time = GetSystemTime();

    // Check if we need to synchronize with the system clock due to a backwards
    // time change or the amount of time elapsed.
    TimeDelta elapsed = ticks - initial_ticks_;
    if (time < initial_time_ || elapsed > kMaxElapsedTime) {
      initial_ticks_ = ticks;
      initial_time_ = time;
      return time;
    }

    return initial_time_ + elapsed;
  }

 private:
  static TimeTicks GetSystemTicks() {
    return TimeTicks::Now();
  }

  static Time GetSystemTime() {
    FILETIME ft;
    ::GetSystemTimeAsFileTime(&ft);
    return Time::FromFiletime(ft);
  }
```

可以看到，`v8` 依赖 windows 系统提供的 [GetSystemTimeAsFileTime](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimeasfiletime) 函数获取系统时间，并将其结果格式化后返回给 JS。如果 `Date.now()` 产生了非预期的结果，很有可能是**系统时间**本身与真实时间产生了差异。

## 不可靠的系统时间

“系统时间”是否就是我们在窗口状态栏上显示的时间，它会影响代码中 `Date.now()` 的结果吗？实践出真知，我们简单的操作验证一下。

```bash
$ node         # 进入 repl
> Date.now()   # 获取一次时间戳
1676984219484
...            # 此时修改系统时间。mac 可以通过 Preference -> Date & Time 界面修改
> Date.now()   # 在同一个进程内，再次获取一次时间戳
1676983919484
```

随着我们手动修改系统时间，系统窗口右上角的时钟展示的时刻也立即变成了相应的值。可以看到，即便在同一个进程中，后续执行的 `Date.now()` 的输出也相应的变成了那个时间。我们把系统时间调整到过去的某个时刻，第二次输出的结果比第一次小了很多。同样的方法，也可以把系统时间往未来的某个时刻，此时输出的结果也是未来的那个时间戳。

这说明了一个问题：**利用两次 `Date.now()` 计算时间间隔，结果可能并不可靠**。这个时间间隔可能极大，也可能是负数，这取决于系统维持的时间是否可靠。或者说，系统维持的时间，本身就可能不可靠。

问题的关键在于这个不可靠会在什么情况下发生。

## 系统是如何维持时间的

系统时间究竟是怎么来的？以下是微软关于系统时间的一段[说明](https://learn.microsoft.com/en-us/windows/win32/sysinfo/system-time)：

> When the system first starts, it sets the system time to a value based on the real-time clock of the computer and then regularly updates the time.

当操作系统启动时，会从计算机的**实时时钟**(real-time clock, RTC)读取时间作为系统的启动时间，并定期更新，以便运行在其中的各种应用程序调用获取。实时时钟是一种小型的电子元器件，在个人电脑中，通常集成在主板上，依赖电源、备用电池（例如主板上的纽扣电池）或超级电容供电。当电脑关机甚至完全切断电源时，实时时钟也记着时间，以备不时之需。

![](/img/2023-02-26/date-now-rtc.jpeg)

可以想象，如果主板上电力耗尽，实时时钟将不能维持。系统启动后，一些依赖时间关系的逻辑可能会产生非预期的异常。好在操作系统对系统时间的取用还具有第二重保险，即利用网络时间协议(Network Time Protocol, NPT)作为外部时间源进行同步。在 Mac 中，打开系统设置时间与日期界面，默认勾选的 `set date and time automatically` 即为系统自动同步时间的设置：

![](/img/2023-02-26/date-now-sys-time-sync.png)

本机硬件设备(RTC)可能由于电源耗尽不可靠，网络协议(NTP)自然也可能由于网络无法访问而不可靠。假设一台电脑在开会途中电源耗尽突然关机，电脑的实时时钟未能更新最新时间。一段时间后，系统接入电源启动。实时时钟得到一个错误的时间（很可能是关机前最后一次同步的时间），并被操作系统读出作为系统时间。好巧不巧，启动后用户的网络未能立即接入，外部的时间服务器同步系统时间也失败。此时应用程序获取的系统时间，只能是一个过去的时间戳了。

回到开头提到的度量 electron 应用启动耗时的场景里，我们**也许**可以做出这样的推断：当操作系统启动后，应用被自动唤起，此时取 `Date.now()` 作为开始时间，得到的是系统时间同步前的一个过去的时间；而窗口出现时，系统时间可能刚刚同步完毕，此时取到的 `Date.now()` 才是真正的当前时间。两时间相减之下，产生大的离谱的间隔，似乎就解释得通了！

## TL;DR

本文仅探讨 electron 应用中取当前时间异常的一些可能的分析，总结如下：

1. `Date.now()` 由 `v8` 提供底层实现，本质上是获取系统时间；
2. 系统时间可能会由于实时时间元件不准、 系统同步时间不及时、用户手动修改系统时间导致产生与真实时间具有较大差异的值；
3. 由于以上两点，利用两次 `Date.now()` 计算时间间隔，结果可能并不可靠。

既然如此，在 electron 应用中，有没有更好的准确度量耗时（或相对时间）的方式？答案是肯定的。限于篇幅，我们以后再行探讨。

## references

- <https://github.com/v8/v8/blob/main/src/base/platform/time.cc>
- <https://learn.microsoft.com/en-us/windows/win32/sysinfo/system-time>
- <https://wiki.archlinux.org/title/System_time>
- <https://en.wikipedia.org/wiki/Real-time_clock>
- <https://unix.stackexchange.com/questions/671083/when-is-the-system-time-synced-to-hardware-clock>
- <https://apple.stackexchange.com/questions/117864/how-can-i-tell-if-my-mac-is-keeping-the-clock-updated-properly>
