---
layout: post
title:  css Masonry layout
date:   2016-11-26 15:51:00 +0800
categories: css
---

前几天做页面的时候, 遇到这样一种情况: 把等宽但是高度不定的一些单元格依次放入容器内。原本以为用浮动会很容易实现, 但是发现浮动换行的时候, 和上一行之间的空隙无法自动填充————每当换行, 就和上一行毫无关联了, 上一行即便有多余的高度空间, 也无法利用。
尝试用 flex 试了试, 也是同样的效果。当时时间有限就没有继续探究。今天探究了一下, 原来这种布局又叫做 `masonry layout`。Masonry 意即"石工", 这种布局有点像填砖块造墙, 不留下"窟窿", 容器空间利用最大化。

### column

所幸我们有了 [`column`](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Columns/Using_multi-column_layouts), 这个 css 属性用来解决多列布局的中的一些痛点, 例如把一篇长文分成左右两侧区块显示内容, 像报纸一样。它有以下一些 css 属性可以定义:

- column-count

    分割的列数
    
- column-width

    每一列的最小宽度。如不设置浏览器会自动按照列数切分, 如果设置了, 会分隔成最大可分的列数。
    
- columns
    
    因为以上`column-count` `column-width` 两个值单位不同并且实际上是只有一个生效的, 所以也可以直接用 columns 来决定列分布。比如 `column: 4` 因为不带单位, 等同于定义 `column-count`; `column: 100px;` 因为带了单位, 等同于定义 `column-width`; 另外可以定义 `columns: 4 100px;`代表每列最小100px, 期望分隔成4列。
    
通过分列, 浏览器已经帮我们计算了一个最大的高度, 因此每一列看上去都几乎等高。但是如果通过 `height` 或者 `max-height` 限制了容器的高度, 那么计算的列高并不会超过高度限制, 因此列数就可能增加。

- column-gap
    
    列之间默认有 1em 的间距, 可以通过设置这个属性更改。
    
### implement

用 column 的方式, 实现起来非常简单。唯一需要注意的是, 子元素必须得设置 `display: inline-block; width: 100%;`, 否则子元素可能被拆成多个块。

```style
.parent {
    columns: 2;
    column-gap: 0;
}

.child {
    display: inline-block;
    width: 100%;
}
```

[示例可见于此](/static/basic-masonry-with-columns.html)

### improvement

现在还有一点需要解决: 以上的排列, 会把内容按照从上到下的序号填满一列, 再换到第二列:

```
1 | 4 | 7
2 | 5 | 8
3 | 6 |
```

但是期望达成的是水平方向填充满了,再换到下一行(每个元素高度不固定, 宽度可以固定):

```
1 | 2 | 3
4 | 5 | 6
7 | 8
```

似乎这和 column 并无关联了, 问题又回到了起点。网上搜了一下, 似乎并没有一种纯CSS的实现方法。当然, 通过JS计算, 是可以做到的。以下是一段实现 marsonry layout

```javascript
const map = new Map()

function getElement (el) {
  if (typeof el === 'string') {
    el = document.querySelector(el)
  }

  return el
}

function getColumnDistribution (num) {
  var arr = []
  for (var i = 0; i < num; i++) {
    arr.push(Math.floor(100 * i / num).toFixed(3) + '%')
  }
  return arr
}

function getHeightDistribution (num) {
  var arr = []
  for (var i = 0; i < num; i++) {
    arr.push(0)
  }
  return arr
}

/**
 * 实现 masonry layout
 */
class Masonry {
  static init (box, config) {
    box = getElement(box)
    var instance = map.get(box)
    if (!instance) {
      instance = new Masonry(box, config)
      map.set(box, instance)
    }
    return instance
  }

  /**
   *
   * slot: 槽选择器
   * columnCount: 列数
   * columnDistribution: 列分布
   *
   * @param config
     */
  constructor (box, config) {
    //  容器
    this.box = box
    //  槽选择器
    this.slotSelector = config.slot
    //  列数
    this.columnCount = config.columnCount
    //  列分布
    this.columnDistribution = config.columnDistribution || getColumnDistribution(this.columnCount)
    //  高度分布
    this.heightDistribution = getHeightDistribution(this.columnCount)
    //  当前最低的那个槽的序号
    this.minIndex = 0
    //  当前处理了的序号
    this.arragedIndex = 0
  }

  /**
   * 重新布局
   */
  resetLayout () {
    this.arragedIndex = 0
    this.heightDistribution = getHeightDistribution(this.columnCount)
    this.minIndex = 0

    this.updateLayout()
  }

  /**
   * 如果 slots 数量变化了, 只布局新增的 slot
   */
  updateLayout () {
    var slots = this.box.querySelectorAll(this.slotSelector)
    var total = slots.length
    for (var i = this.arragedIndex; i < total; i++) {
      let slot = slots[i]
      let rect = slot.getBoundingClientRect()
      slot.style.cssText = `left: ${this.columnDistribution[this.minIndex]}; top: ${this.heightDistribution[this.minIndex]}px;`
      this.heightDistribution[this.minIndex] += rect.height
      let min = Math.min.apply(Math, this.heightDistribution)
      this.minIndex = this.heightDistribution.indexOf(min)
      this.arragedIndex ++
    }

    let max = Math.max.apply(Math, this.heightDistribution)
    this.box.style.cssText = `height:${max}px;`
  }
}

export default Masonry
```