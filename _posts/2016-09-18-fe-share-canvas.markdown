---
layout: post
title:  fe-share-canvas
date:   2016-09-09 22:53:00 +0800
categories: canvas
---

## 一张白纸: Canvas

### 简介    
    
&lt;canvas&gt; 是HTML5标准里新增的一个元素标签。它是一张空白的画布, 为了在画布上进行创作, 通过`canvas.getContext()`访问特定绘图环境提供的一系列 API。 
可以实现以下功能, 主要包含: 
    
- Image/Canvas元素的填充绘制 `drawImage`
- 矩形区域绘制 `fillRect`
- 路径绘制 `beginPath` `moveTo` `lineTo` `endPath` `arc` `bezierCurveTo`
- 文本绘制 `fillText`
- 线条及填充 `beginStroke`, `beginFill`, `stroke`, `fill`
- 混合模式, 用来决定接下来的绘制内容如何与当前画布上已有内容相叠加

以上内容可以在 [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Basic_usage) 详细查看
    
### 宽、高与二维坐标体系
    
画布的宽 `canvas.width`、高 `canvas.height` 决定了画布的绘图范围大小。画布的样式宽 `canvas.style.width`、高 `canvas.style.height` 决定了画布显示在页面上的大小。它们之间没有必然的对应关系;
只是如果画布的 `宽高比` 与其 `样式宽高比`一致, 那么画布内容不会变形; 否则会失去应有的长款比, 导致方不方、圆不圆。这一点和 &lt;img&gt; 标签是类似的。

画布左上角是坐标轴原点(0, 0)。水平方向是 x 轴并且向右是 x 轴正方向; 垂直方向是 y 轴并且向下是 y 轴正方向。如果某绘制元素部分或者完全不在这一块矩形区域内, 不影响其定位或计算, 仅仅是超出的内容不绘制而已。

![](https://mdn.mozillademos.org/files/224/Canvas_default_grid.png)

### 显示对象, 容器

先做一个简单的绘制: 预载9张图标, 把每个图标按次序排列在 3x3 的空间内。代码如下:

```javascript
var canvas = document.querySelector('#myCanvas')
canvas.width = window.innerWidth
canvas.height = window.innerHeight
var ctx = canvas.getContext('2d')

function preload (list) {
    var loaded = 0
    var total = list.length
    for (var i = 0; i < total; i++) {
        var img = new Image()
        img.src = list[i]
        imgList.push(img)
        img.onload = (e) => {
            loaded ++
            if(loaded == total){
                start()
            }
        }
    }
}

var preloadList = [
    '/static/icon_1.png',
    '/static/icon_2.png',
    '/static/icon_3.png',
    '/static/icon_4.png',
    '/static/icon_5.png',
    '/static/icon_6.png',
    '/static/icon_7.png',
    '/static/icon_8.png',
    '/static/icon_9.png',
    '/static/icon_10.png'
]
var imgList = []

preload(preloadList)

function start() {
    imgList.forEach((img, index) => {
            var row = index % 3
            var col = Math.floor(index / 3)
            ctx.drawImage(img, row * 100, col * 100)
        })
}

```

效果如图: 
![](../img/01-lined-icons.png)

如果只是静态的绘制, 这样完全没有问题。但是如果需要对特定的图标做单独的调整, 因为画布是一个整体, 也并没有记住单独某个图标的状态, 可能需要擦除整个画布, 再重新绘制每个元素, 并且对想要调整位置的图标单独处理

现在把画布作为一个 "容器"(Container). 容器内的每一个独立的视图部分, 称之为 "显示对象"(DisplayObject); 它们每个都有各自的坐标(x, y); 它们都是这个容器的"子元素"(children)。

当我们需要改变画布内容时, 找到想要改变的那个显示对象, 读取并修改相关属性, 最后刷新容器即可

代码如下:

```javascript
function start() {
    imgList.forEach((img, index) => {
        var row = index % 3
        var col = Math.floor(index / 3)
        var bitmap = new DisplayObject(img)
        bitmap.x = row * 100
        bitmap.y = col * 100
        children.push(bitmap)
    })

    updateView()
}

//  子显示对象合集
var children = []
//  更新视图的方法
function updateView () {
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    children.forEach((child) => {
        child.draw()
    })
}

//  显示对象构造方法
var DisplayObject = function (img) {
    this.img = img
    this.x = 0
    this.y = 0

    this.draw = function () {
        ctx.drawImage(this.img, this.x, this.y)
    }
}
```

在以上的代码中, 9个图标由 9个 DisplayObject 所持有; 只需要改变某个显示对象的相关属性, 并最终刷新视图(updateView), 即可更新画布内容。

### "动"画的实现: requestAnimationFrame

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

### 逐帧运动

### 序列帧动画: Sprite(MovieClip)

### 更快捷的动画: 使用第三方Tween

#### 自适应策略

#### 缓动原理

#### 速度, 加速度, 重力, 反弹

### 使用第三方类库

-   createjs

-   Egret