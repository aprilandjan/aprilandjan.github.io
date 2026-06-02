---
layout: post
title:  css gradient border
date:   2017-03-14 11:10:00 +0800
categories: css
---

最近遇到了这样一个需求，制作带有渐变色填充的边框：
![](/img/color-border.png)

拿到设计稿，首先想到的办法是使用 css 里的 `border`, `border-radius` 定义元素的边框样式和圆角程度，除了需要处理一下水平方向渐变填充，仿佛和普通的边框并没有多大的区别。

### 渐变填充

一块渐变填充，往往需要定义它的填充方向（线性的，或者是迳向的），然后在这块方向上，从起点比例位置（0%）到结束点比例位置（100%）定义每一个渐变区间的颜色值，如此一来，整个绘制区域内就能依据比例位置和颜色范围实现渐变的填充了。

理解了上述原理，在 css 里实现渐变填充就很容易了。比如, 通过`linear-gradient(to right, red, yellow)`就创建了一个从左到右、由红至绿的渐变填充样式。那是不是直接定义 `border-color: linear-gradient(to right, red, yellow)` 就可以了呢？尝试了一下，并没有效果。参看 MDN上的[相关资料](https://developer.mozilla.org/en-US/docs/Web/CSS/linear-gradient):

> The CSS linear-gradient() function creates an `<image>` which represents a linear gradient of colors. The result of this function is an object of the CSS `<gradient>` data type. Like any other gradient, a CSS linear gradient is not a CSS `<color>` but an image with no intrinsic dimensions;

原来，通过 `linear-gradient` 创建的样式实际上是图片，而不是颜色，而 border-color 是不接受图片作为值的。既然如此，应该是可以用在 `border-image` 

以下是使用的方法：

```css
.box {
  border: 20px solid;
  border-image: linear-gradient(to right, red, yellow) 10;
  padding: 20px;
  border-radius: 20px;
}
```

经过测试，发现圆角属性 `border-radius` 并不生效。查阅相关资料发现 `border-image` 本身就不支持混用圆角。这样以来，单纯使用 `border` 的方式就不行了。 

### `pseudo element`: `:before`

不得已，只好换个实现方式，用多个层级来处理。用 `:before` 制作渐变的底色，再让元素自身内容区域为白色盖在渐变底色下，两层都各自有一定的圆角，以此达到渐变边框的效果：

```css
.box {
  background-color: white;
  position: relative;
  border-radius: 12px;
  margin: 10px;
}

.box:before {
  content: '';
  display: block;
  position: absolute;
  left: -10px;
  top: -10px;
  right: -10px;
  bottom: -10px;
  background: linear-gradient(to right, red, yellow);
  z-index: -1;
  border-radius: 20px;
}
```

但是这个方法也有缺陷：当给它的父级或者更底层的节点设置了背景色的时候，因为渐变层级 `z-index = -1` 的关系，导致它被父级盖住。为此需要做一些调整，让渐变底色的 `z-index` 比默认的层级要高，那么容器内的真实内容的层级必须要更高。所以只好给容器内容再嵌套了一层容器，样式如下:

```css
.box {
  position: relative;
  margin: 10px;
}

.box:before {
  content: '';
  display: block;
  position: absolute;
  left: -10px;
  top: -10px;
  right: -10px;
  bottom: -10px;
  background: linear-gradient(to right, red, yellow);
  z-index: 1;
  border-radius: 20px;
}

.box-content {
  position: relative;
  z-index: 2;
  background-color: white;
  border-radius: 12px;
}
```

通过以上的步骤，终于能大致实现满足需求的样式了。还有一点需要注意的是：垫在底下的渐变层的 `border-radius` 和内容区域的 `border-radius` 的值需要相匹配，否则圆角的那部分看起来粗细就不一致了。具体应该如何匹配，可以手动调整观察，也可以根据边框粗细程度计算，大致上应该如此计算：`borderRadius(外) - borderWidth(外) = borderRadius(内)`。
