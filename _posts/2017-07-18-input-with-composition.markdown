---
layout: post
title:  input-with-composition
date:   2017-07-18 22:26:00 +0800
categories: html javascript
---

很久没写东西了。几个月来工作上参与的项目变更，不停的学习、接触了一些新的东西，颇有疲累之感。前端这一块，除了语言号称是 javascript, 换个框架相当于又换了一个天地，得时时刻刻追赶发展的步伐，让人觉得有些浮躁。

回到正题。最近才发现 `input` 元素的 `onChange` 事件，在键入由输入法复合而成的内容（例如拼音输入法输入汉字）的过程中也会触发，并且触发时获取到的元素 `value` 值是未完成复合输入的值。这种行为可能会造成不必要的行为：比如在一个搜索输入框内，需要根据用户键入的有效内容筛选信息，如果是输入复合状态下的值其实是无效的，不应处理的。做了这么久的前端都不知道这个事，看来我还是组件写的少了...

有没有方法知道用户当前的输入法输入是否是直接的文本还是复合成的文本呢？答案是肯定的。`input` 元素拥有一系列 [`CompositionEvent`](https://developer.mozilla.org/en-US/docs/Web/API/CompositionEvent), 通过这些事件可以得知当前输入的复合开始、复合更新、复合结束状态，从而达到我们想要的效果。基本思想就是：当 `compositionstart` 触发时，标记状态位 `isCompositing` 为真; 当 `compositionEnd` 时，复合结束，用户的输入此时是有效的，可以处理输入改变事件；而原本的 `change` 事件内需判断是否是在复合状态，如是，则不处理输入改变事件。

以下是一个极为简洁的处理此情况的 `React` 组件。不得不说 `React` 的编程理念是比较纯粹的，和 `vue` 相比各有各的美感体验。

```javascript
import React from 'react'

export default class SearchInput extends React.Component {
  constructor () {
    super()

    this.onComposition = this.onComposition.bind(this)
    this.onChange = this.onChange.bind(this)
    this.isCompositing = false
  }

  onComposition (e) {
    if (e.type === 'compositionstart') {
      this.isCompositing = true
    } else {
      this.isCompositing = false
      this.callHandler(e)
    }
  }

  onChange (e) {
    if (!this.isCompositing) {
      this.callHandler(e)
    }
  }

  callHandler (e) {
    const { onChange } = this.props
    if (onChange && onChange instanceof Function) {
      this.props.onChange(e)
    }
  }

  render () {
    return (
      <input {...this.props} onCompositionStart={this.onComposition}
        onCompositionEnd={this.onComposition}
        onChange={this.onChange}/>
    )
  }
}
```

使用起来，只需要把它当作普通的文本输入元素，监听 `onChange` 事件即可。文件链接在[这里](https://github.com/aprilandjan/react-starter/blob/test/search-input/src/components/SearchInput.js)。