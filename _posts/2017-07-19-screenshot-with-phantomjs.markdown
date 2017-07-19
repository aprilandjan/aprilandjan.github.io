---
layout: post
title:  screenshot with phantomjs
date:   2016-11-30 10:30:00 +0800
categories: phantomjs javascript
---

以前曾尝试使用了一下 phantomjs 打开某页面、模拟页面上交互操作并截图等。这次因为有需求要截取一个使用 vue 全家桶开发的单页应用，原本很简单的截图却遇到了一些问题，现记录如下：

## 载入页面后控制台显示报错：`vuex requires a Promise polyfill in this browser`

因为页面本身在 chrome 里运行一切正常，此报错又提示在 phantomjs 的无头浏览器环境下找不到 promise, 所以解决问题的思路变成了在源代码内补上 promise polyfill。参考[ReferenceError: Can't find variable: Promise](https://github.com/ariya/phantomjs/issues/12401), 在前端项目中添加 [es6-promise](https://github.com/stefanpenner/es6-promise) 作为依赖，并且在入口文件第一行加上 polyfill 的自动判断:

```javascript
import 'es6-promise/auto'
```

注意这里引入必须要使用 `import` 而不是 `require`, 因为 `import` 声明的语句经过编译后总是被提升到了文件顶部，执行的比其他的代码要早，所以如果是先 `require('es6-promise/auto')` 再 `import vuex` 的情况下，仍然会报错...另外，尝试了一下，`vuex` 目前如果使用 `es6-promise` 提供的 promise，内部的`registerAction` 方法会报错，但不影响正常工作。可能是 `es6-promise` 实现 promise 与浏览器源生 promise 存在差异引起的。

## 延迟截图，自动图片高度，异常处理

截图延迟写的延迟方法不要用箭头函数，否则会执行不到。可能是因为定时回调的作用域被肩头函数干扰了；另外仿佛没有自动截取完整网页的功能，需要通过 `evaluate` 调用页面内的 js 取得元素的高度来裁剪截图的尺寸；最后，为了便于其他进程调用的状态判断，在异常的情况下给出 `exit(1)` 帮助区分

## 完整代码

```javascript
var system = require('system')
var args = Array.prototype.slice.call(system.args, 1)

var url = args[0] || 'http://localhost:8080/#/'
var output = args[1] || 'screenshot.jpg'

var size = {
    width: 1300, 
    height: 8000
}

var page = require('webpage').create()
page.settings.userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1'
page.viewportSize = size

page.onConsoleMessage = function(msg) {
    console.log('page:\n' + msg);
}

phantom.onError = function(msg, trace) {
  var msgStack = ['PHANTOM ERROR: ' + msg];
  if (trace && trace.length) {
    msgStack.push('TRACE:');
    trace.forEach(function(t) {
      msgStack.push(' -> ' + (t.file || t.sourceURL) + ': ' + t.line + (t.function ? ' (in function ' + t.function +')' : ''));
    });
  }
  console.error(msgStack.join('\n'));
  phantom.exit(1);
};

page.onLoadFinished = function() {
    window.setTimeout(function () {
        var width = page.evaluate(function(){
            var app = document.getElementById('app')
            return app ? app.offsetWidth : 1024;
        });
        var height = page.evaluate(function(){
            var app = document.getElementById('app')
            return app ? app.offsetHeight : 768;
        });
        page.clipRect = { top: 0, left: 0, width: width, height: height };
        page.render(output) // {format: 'jpeg', quality: '100'}
        phantom.exit(0)
    }, 2000)
};

page.open(url, function (status) {
    console.log(status)
})
```


## 总结


