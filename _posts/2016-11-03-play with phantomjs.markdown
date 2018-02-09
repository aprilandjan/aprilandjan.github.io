---
layout: post
title:  play with phantomjs
date:   2016-11-03 15:30:00 +0800
categories: node
---

phantomjs 是一个无界面的webkit浏览器, 可以通过它在服务器端直接用JS代码访问页面中的各种元素、方法和属性, 甚至截取屏幕。

### 安装

全局安装即可, 以后再需要局部安装时会检测时候有全局安装, 有的话会引用全局安装的包。

```bash
npm install -g phantomjs --phantomjs_cdnurl=http://npm.taobao.org/mirrors/phantomjs
```

完成之后可以通过 `phantomjs -v`查看是否全局安装成功

### 运行

使用 `phantomjs ./test.js` 即可执行指定路径下的文件。在这里尝试使用phantomjs登录百度并且截屏:

```test.js
var page = require('webpage').create()
page.settings.userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1'
page.viewportSize = { width: 750, height: 1334 }

var loadInProgress = true
var pageIndex = 0

page.onConsoleMessage = function(msg) {
    console.log('===CONSOLE===\n' + msg);
}

page.onLoadStarted = function() {
    loadInProgress = true;
    console.log("===load started===");
};

page.onLoadFinished = function() {
    loadInProgress = false;
    console.log("===load finished===");
    pageIndex ++

    if(pageIndex == 1) {
        delayedCall(goLogin)
    }
    else if(pageIndex == 2) {
        delayedCall(submit)
    }
    else {
        delayedCall(snapshot)
    }
};

function goLogin () {
    page.evaluate(function() {
        var evObj = document.createEvent('Events');
        evObj.initEvent('click', true, false);
        document.getElementById('login').dispatchEvent(evObj);
    })
}

function submit() {
    page.evaluate(function () {
        document.getElementById('login-username').value = 'my-username'
        document.getElementById('login-password').value = 'my-password'
        document.getElementById('login-submit').removeAttribute('disabled')
        var evObj = document.createEvent('Events');
        evObj.initEvent('click', true, false);
        document.getElementById('login-submit').dispatchEvent(evObj);
    })
    snapshot()
}

function snapshot () {
    window.setTimeout(function () {
            page.render('snapshot.jpg', {format: 'jpeg', quality: '100'})
            // phantom.exit()
        }, 3000)
}

function delayedCall (cb) {
    setTimeout(cb, 500)
}

page.open('https://www.baidu.com', function () {
    // Todo
})
```
