---
layout: post
title:  css animation event
date:   2016-12-22 21:30:00 +0800
categories: javascript
---

最近做页面, 某个动画可能要监听一段 css animation 动画的完成事件。查了一下相关资料, 发现 animation 相关的事件在不同设备上还是有区别的。下表总结的比较全:

| W3C standard        | Firefox           | webkit  | Opera | IE10 |
|:-------------:|:-------------:|:-----:|:-----:|:-----:|:-----:|
| animationstart     | animationstart|	webkitAnimationStart|	oanimationstart| MSAnimationStart|
| animationiteration | animationiteration	|webkitAnimationIteration|	oanimationiteration|	MSAnimationIteration|
| animationend | animationend|	webkitAnimationEnd|	oanimationend|	MSAnimationEnd|

可以看到, webkit 以及 ms 的时间名特立独行, 单词首字母用大写——这点很重要, 因为写小写的话并不会触发这个事件。安卓微信内的X5也是同样的, 实测需要监听 webkitAnimationEnd 才可以触发事件。

以下是一种兼容的事件侦听方法:

```javascript
var pfx = ['webkit', 'moz', 'MS', 'o', ''];
function prefixedEventListener(element, type, callback) {
  for (var p = 0; p < pfx.length; p++) {
    var t = (p == 0 || p == 2) ? type : type.toLowerCase()
    element.addEventListener(pfx[p]+t, callback, false);
  }
}
```

---

##### 参考
- [How to Capture CSS3 Animation Events in JavaScript](https://www.sitepoint.com/css3-animation-javascript-event-handlers/)