---
layout: post
title:  css flex layout
date:   2016-11-20 13:30:00 +0800
categories: css
---

一直以来都没有系统的学习CSS, 只是根据经验做一些常规的排版布局, 大概也就是初略理解了三层盒模型以及relative, absolute定位的关系, 基本上做一些静态的、非响应式的, 这样已经足够了。
前几天接触到一个叫 [bulma](http://bulma.io/) 的 css 框架, 看了看文档, 对 css 的样式提炼的很不错, 比以前看 bootstrap 的时候感觉更精彩。css 能拆解到这种地步, 很让人佩服。
这个框架一些响应式的布局方案, 基本都是用 flex 来实现的, 而自己以前从未用过 flex, 趁此机会, 学习一下 flex 布局, 以后无论是用还是自己写可能都会有用武之地。

### Document

MDN上的[文档](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout/Using_CSS_flexible_boxes)还是很详细的, 
也可以对照阮一峰[博文](http://www.ruanyifeng.com/blog/2015/07/flex-grammar.html) 对比参看。

#### 容器属性

设置容器 `display: flex`, 它的所有子元素自动成为容器项目`flex-item`, 然后可以设置以下6个容器属性:

- flex-direction: 定义主轴(main-axis)方向, 也是子项排列方向。可以定义以下4个值
    
    - row: 水平从左到右, 从容器左侧开始排列
    - row-reverse: 水平从右到左, 从容器右侧开始排列
    - column: 垂直从上到下
    - column-reverse: 垂直从下到上, 从容器底部开始排列
    
- flex-wrap: 类似 `white-space: no-wrap`, 定义当一行排列不下的时候, 是否需要换行。默认是不换行, 并且每个子元素等分容器的。可以定义以下值:

    - no-wrap: 不换行
    - wrap: 换行
    - wrap-reverse: 换行但新行的位置与wrap相反
    
- flex-flow: 以上两个参数的组合, 例如 `flex-flow: row wrap`

- justify-content: 子项沿着主轴(main axis)的分布方式。可以定义以下值:

    - flex-start: 子项放在主轴开始处
    - flex-end: 子项放在主轴结束处
    - center:  子项放在主轴中心, 相当于 `text-align: center` 了
    - space-between: 子项等间距的填满主轴
    - space-around: 子项具有相等的周围间隔, 包括主轴上第一个以及最后一个
    - space-evenly: MDN上有这个值, 但是在chrome上测试此值无效
    
- align-item: 子项沿着交叉轴(cross axis, 主轴垂线方向)的分布方式。类似于 `vertical-align`, 对单独的一行内的元素起作用。 可以定义以下值: 

    - flex-start: 子项靠着交叉轴开始处
    - flex-end: 子项靠着交叉轴结束处
    - center: 沿着交叉轴中心, 大概也相当于 `vertical-align: middle`?... 感觉属性值标准很混乱的样子
    - baseline: 子项的第一行文字基线对齐
    - scratch: 默认值。如果子项没有定义高度或者设置成 auto, 那么会拉伸至整个行

- align-content: 多个沿着主轴的内容行列在容器内的分布方式。可定义的值以及效果和 justify-content 类似。

#### 子项属性

- order: 排列优先级, 类似于 `z-index` , 默认值是0. 不过在 flex 布局里是越小, 排列越靠前。
    
- flex-grow: 对排列里剩余空间的利用的值。默认是0, 不利用任何剩余空间; 最大有效值是1, 该子项会按照此值的定义, 扩展剩余空间的一定比例到自己的大小上。如果一行内多个子项均占有一定的比例, 且和超过了1, 会归一化计算各自的占比。

- flex-shrink: 当排列里空间不足时, 子项目缩小的比例值, 默认是1, 如果定了大小不想让它变化, 需要手动指定此值为0. 有点难以理解排列空间不足..
 
- flex-basis: 该项目在主轴方向上占据的空间。默认是auto, 本来的大小。flex 会根据此值计算主轴上的剩余空间大小

- flex: 以上三个参数的组合, 例如 `flex: 1 1 10%` 分别定义了 `flex-grow: 1; flex-shrink: 1; flex-basis: 10%;`

- align-self: 拥有该属性的子项会覆盖掉容器的 align-item 给它的定位。值与 `align-item` 完全一样

#### 实践

配合媒体查询, 小小的实现一下 MDN 上的圣杯布局。可见 flex layout 的确是非常好用的。页面代码如下:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Learning Flex Box</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            text-align: center;
            background-color: #ccc;
            font-family: Helvetica, Arial, sans-serif;
            color: midnightblue;
        }

        header {
            padding: 10px;
            height: 50px;
            background-color: white;
        }

        main {
            display: flex;
            align-items: stretch;
            width: 768px;
            margin: 0 auto;
        }

        .nav-left {
            width: 20%;
            background-color: bisque;
            flex-shrink: 0;
        }

        .content {
            width: auto;
            height: 500px;
            flex-grow: 1;
            background-color: cadetblue;
        }

        .nav-right {
            width: 20%;
            background-color: cornflowerblue;
            flex-shrink: 0;
        }

        footer {
            padding: 10px;
            height: 50px;
            background-color: white;
        }

        @media (max-width: 768px) {
            main {
                flex-direction: column;
                width: 100%;
            }

            .nav-left {
                width: 100%;
            }

            .nav-right {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <header>
        Navigation Here
    </header>

    <main>
        <nav class="nav-left">
            Left Nav
        </nav>
        <article class="content">
            <h2>Content</h2>
            <article>
                Smecasthsa lecaots waksq Smecasthsa lecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots
                1asSmecasthsa l1ecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksq
                s  Smescasthsa lecaots waksq1as 123s
                sda Smecasthsa lecaots waksq s
                as  Smecasthsa lecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksq
                waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksqSmecasthsa lecaots waksq
            </article>
        </article>
        <aside class="nav-right">
            Right Nav
        </aside>
    </main>

    <footer>
        Page Footer
    </footer>
</body>
</html>
```

页面在[这里](/static/holy-grail-by-flex-layout.html)