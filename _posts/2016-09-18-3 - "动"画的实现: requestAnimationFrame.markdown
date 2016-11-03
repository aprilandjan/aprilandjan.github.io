---
layout: post
title:  3 - "动"画的实现:requestAnimationFrame
date:   2016-09-18 16:30:00 +0800
categories: canvas
---

动画是画面随时间变动的效果。无论是用何种方式的随时间变动(setInterval, setTimeout), 都是可以驱"动"的; 但是在浏览器端, 使用 requestAnimationFrame 获取的定时间隔更平稳可靠。参考: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame)

以下是一个简单的驱动动画的方法, 我们把它命名为 Ticker.js, 用来驱动更新视图:
```javascript Ticker.js
var _raf
var _callbacks = []
var _tick = function () {
    _callbacks.forEach(cbArr => {
        var callback = cbArr[0]
        var scope = cbArr[1]
        callback.call(scope)
    })

    window.requestAnimationFrame(_tick)
}


class Ticker {
    constructor () {
        _raf = window.requestAnimationFrame(_tick)
    }

    /**
     * 注册一个每帧回调到 Ticker
     * @param callback
     * @param scope
     */
    on (callback, scope) {
        var result = _callbacks.filter(cbArr => {
            return callback == cbArr[0] && scope == cbArr[1]
        })

        if(!result.length){
            _callbacks.push([callback, scope])
        }
    }

    /**
     * 从 Ticker 内移除一个每帧回调
     * @param callback
     * @param scope
     */
    off (callback, scope) {
        for (var cbArr of _callbacks) {
            if(cbArr[0] == callback || cbArr[1] == scope){
                _callbacks.splice(_callbacks.indexOf(cbArr), 1)
            }
        }
    }
}

var instance = new Ticker()
export default instance
```

结合上例, 让每个小图标(DisplayObject)单独在自己原本的位置周围做随机运动, 形成一种 'shaking' 的效果:

```javascript
Ticker.on(() => {
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    children.forEach(child => {
        if (!child.originPos) {
           child.originPos = {
               x: child.x,
               y: child.y
           }
        }

        child.x = child.originPos.x + 10 * Math.random() - 5
        child.y = child.originPos.y + 10 * Math.random() - 5

        child.draw()
    })
})
```

效果如下图:
![](../img/02-shake.gif)

### 获取交互坐标, 触碰检测, 层级管理

当点击画布时, 要想获得事件点相对于画布内的坐标位置, 可以通过如下方式:

```javascript
canvas.addEventListener('click', (e) => {
    //  获取canvas所占据的矩形区域
    var rect = canvas.getBoundingClientRect()
    var x = e.clientX - rect.left   //  px
    var y = e.clientY - rect.top    //  px

    //  canvas内的实际坐标点
    x *= canvas.width / canvas.offsetWidth
    y *= canvas.height / canvas.offsetHeight
})
```

现在已经知道了画布内发生 click 事件的坐标(x, y), 为了判断在这次点击的位置触碰到了哪些显示对象, 需要一种碰撞检测的判定方法。
最简单的, 遍历全部子对象, 检查触碰点是否在这个子对象的矩形区域范围内。如果有触碰到的, 使它静止下来

```javascript
//  hit area detect
var hits = children.filter(child => {
    return x >= child.x && x <= child.x + child.img.width && y >= child.y && y <= child.y + child.img.height
})

//  让触碰到的显示对象中心移动到(x, y)位置
hits.forEach(hit => {
    hit.static = true   //  make it static
    hit.x = x - hit.img.width / 2
    hit.y = y - hit.img.height / 2
})
```

改进: 因为图片的内容实际上是圆形,以上的矩形区域检测并不精准。可以根据实际情况, 检测事件点到图标中心的距离是否小于图标半径来判定是否碰撞

```javascript
var hits = children.filter(child => {
    return Math.sqrt(Math.pow(child.x + child.img.width / 2 - x, 2) + Math.pow(child.y + child.img.height / 2 - y, 2)) <= child.img.width / 2
})
```

有时候, 点击到的显示对象可能会被其他的元素盖住, 此时需要改变对象的层级。好在可以通过 children 数组快速达成这一目标

```javascript
hits.forEach((hit) => {
    children.splice(children.indexOf(hit), 1)
    children.push(hit)
})
```