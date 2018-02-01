---
layout: post
title:  customize-webpack-loader
date:   2018-01-26 21:33:00 +0800
categories: webpack
---

对前端开发来说, webpack 可能是目前使用最广泛的一款打包工具了。npm 上有各式各样的 loader 用来处理前端可能用到的各种资源文件，应该也能满足一般业务需求。但有的时候有一些小众的特殊需求，需要对特定的资源文件做处理，这时自己在项目里写自定义的 loader 来处理源文件可能会更方便一些。

在 [webpack 官网](https://webpack.js.org/api/loaders/)上已经对 loader 以及如何自定义 loader 有比较详细的文档，也比较好理解，因为它的本质就是对来自文件资源的筛选、输入、转换、输出的方法，因此这里也就不再赘述。以下通过两个实际业务中的需求，构造简单的自定义 loader 来解决问题。

## 解决 antd 字体文件本地化问题

在某个使用 `antd` 的项目里，发现有时会向阿里 cdn 请求特定的字体资源。经查，发现在引入 `antd` 中的 `Icon` 组件之后，对应的样式里包含一套 Icon 字体定义，而这套字体的来源在源代码里写死了就是来自阿里 cdn 。但是很多情况下并不想让这些资源走阿里 cdn ，因此需要一种策略去修改字体定义的源。于是就有以下解决办法：

1. 不引入会加载字体文件的部分组件。这样得分辨哪些组件是会引入字体文件的，自己得另外实现相关组件，反而失去了使用组件库的初衷，不推荐；

2. 定制一份 `antd`, 改写样式中的字体源。仅仅是为了本地化使用字体文件而这样做，感觉大费周章，颇为麻烦，不推荐；

3. 在使用时改写字体文件源。简单来说就是对原样式文件进行字符串替换，把网络路径修改成本地相对路径。这种方式修改成本最小，通过自定义 loader, 实现起来也比较容易。

### antd-local-icon

首先找到要处理的目标文件。因为项目中使用了 `babel-plugin-import` 这个插件用来帮助模块化加载 antd 组件并且配置了样式加载类型为 `css`, 所以字体定义是通过对应组件目录内的 `.css` 文件引入的。我们需要做的就是在引入 `.css` 文件时做好转换处理即可。

以下是基于 webpack 1.x 版本的对 `css` 类型文件处理的 loader 定义：

```javascript
  {
    test: /\.css$/,
    loader: 'style!css!antd-local-icon?url=/main/fonts/'
  }
```

上面这串配置的含义是: 通过正则 `/\.css$/` 匹配输入资源，匹配到的资源 (.css文件) 将会被 `loader` 中定义的 loader 序列处理。这里 loader 是一个从右到左的处理序列，用 `!` 分隔开。一份 `.css` 文件首先通过右侧第一个 loader 也就是 antd-local-icon 处理（并且附带上参数 url=/main/fonts/), 经它处理完之后，再依次交由后续的 `css-loader`、`style-loader` 处理并最终整合到应用代码中。`antd-local-icon` 就是自定义的 loader 了，下面是它的实现代码：

```javascript
//  antd-local-icon-loader
const loaderUtils = require('loader-utils')

module.exports = function (content) {
  //  loader cache automatically
  this.cacheable()

  var filePath = this.resourcePath
  if (filePath.indexOf('antd/lib/style/index') < 0) {
    return content
  }

  var query = loaderUtils.parseQuery(this.query)
  var url = query.url || '/assets/fonts/'
  if (typeof content === 'string') {
    return content.replace(new RegExp('https://at.alicdn.com/t/', 'ig'), url)
  }

  return content
}

```

代码中引入了 `loader-utils` 这个模块, 用来解析 `loader` 规则定义时附带的 `query` 参数——这个模块，如果是正常配置的 `webpack` 项目，应该已被其他的 `loader` 模块所引入过了。函数内的 `this` 指向 webpack 调用 loader 时给予的上下文环境，通过它可以获取配置参数、资源路径等信息，因此可以进一步做判断，避免无意义的转换处理。如果是目标文件(路径包含 `antd/lib/style/index`)，则通过正则全局替换网络地址为本地资源路径，再传递给后续 `loader` 处理。

最后，为了使 webpack 能够从默认的 `/node_modules` 目录以外的路径查找自定义 `loader`, 需要配置参数 `resolveLoader` `fallback` 如下:

```javascript
module.exports = {
  ...
  resolveLoader: {
    root: path.join(__dirname, 'node_modules'),
    fallback: [
      path.resolve(__dirname, './loaders'),
      path.join(process.cwd(), 'node_modules')
    ]
  },
  ...
}
```

## 解决 vue 项目多主题样式定义问题

为了给某个使用 `vue` 框架开发的站点页面添加另外一套主题样式，可能最好的方式是提炼组件和样式，根据主题风格制定一套合适的预处理样式变量，后续再定制变量来改变风格即可。但是有时也需要针对某些组件做不同的样式效果，仅依赖样式变量无法满足。所幸的是, `vue` 支持单个文件内含多个样式块 `<style></style>`)，我们完全可以把不同的主题的样式集中放在不同的样式块内，不同的主题块引入不同的主题变量文件。理想情况下，如果要切主题，只需要改变跟根节点元素 class 即可。当然了，如果不做处理，这些样式块都会包含在最终打包的文件中。这个可以后续再改进下打包、加载机制。

可以对 `vue` 文件略为扩展一下规则：写入多个样式块并自定义主题`<style theme="dark"></style>` `<style theme="light"></style>`用来区分，通过自定义 `loader` 读取这些样式块并根据主题字段 `theme` 做相应的拼接处理，仅把对应主题的变量文件引入，再把这些专属样式包裹在以主题名命名的大节点下，拼接文件输出内容给 `vue-loader` 正常载入解析，最终生成一份样式合集。

以下是一份代码实现, 基于 `webpack` v1.x 以及 `vue` v1.x 开发:

```javascript
/* eslint-disable */
const path = require('path')
// const parse = require('vue-loader/lib/parser');
const parse = require('./vue-parser')
const loaderUtils = require('loader-utils')
const _ = require('lodash')
var parse5 = require('parse5')

var splitRE = /\r?\n/g
var emptyRE = /^\s*$/
var themeKey = 'themed'

// [
//   { name: 'lang', value: 'scss' },
//   { name: 'themed', value: '' }
// ]
function restoreAttrs (attrs) {
  let str = _.reduce(attrs, (acc, attr, k) => {
    let name = attr.name
    let value = attr.value

    //  过滤掉 theme-loader 的属性 theme, 避免传入 vue-loader的内容是不标准的
    if (name === themeKey) {
      return acc
    }

    //  生成属性字串
    let result = ` ${name}`;
    if (value !== undefined && value !== '') {
        result += `="${attr.value}"`
    }
    return acc + result
  }, '')
  return str
}

//  获取指定名称的属性
function getAttribute (node, name) {
  if (node.attrs) {
    var i = node.attrs.length
    var attr
    while (i--) {
      attr = node.attrs[i]
      if (attr.name === name) {
        return attr.value
      }
    }
  }
}

//  重新生成文件结构
function restoreSection (tag, section) {
  if (!section) {
    return ''
  }
  const attrs = restoreAttrs(section.attrs);
  const content = '\n' + (section.content || '').trim() + '\n';
  return `<${tag}${attrs}>${content}</${tag}>\n`
}

function restoreSections (tag, sections) {
  if (!sections) {
    return
  }
  return sections.map(s => {
    return restoreSection(tag, s)
  }).join('\n')
}

//  把主题样式文件插入到样式部分头部
function wrapStyleWithTheme (style, themeName, themeValue) {
  let clone = _.clone(style)
  clone.content =`\n${themeValue}\n.${themeName} {\n${indentLines(clone.content.trim())}\n}\n`
  return clone
}

//  给需要包裹的添加 2 个字符长度的缩进
function indentLines (content) {
  var lines = content.split(splitRE)
  return lines.map((line, index) => {
    // preserve EOL
    if (index === lines.length - 1 && emptyRE.test(line)) {
      return ''
    } else {
      return (emptyRE.test(line) ? '' : '  ' + line)
    }
  })
  .join('\n')
}

//  判断是否是sass(scss)文件
function isLangSass (lang) {
  return lang === 'scss' || lang === 'sass'
}

//  在字符串特定字串后面插入文本
function insertAfter (source, content, identity) {
  if (!identity) {
    return content + source
  }
  var index = source.indexOf(source)
  return source.replace(new RegExp('(' + identity + ')'), content)
}

module.exports = function (content) {
  //  loader cache automatically
  this.cacheable()

  var query = loaderUtils.parseQuery(this.query)
  var themes = query.theme || {}
  var filePath = this.resourcePath
  var fileName = path.basename(filePath)
  var parts = parse(content, fileName)
  //  最终生成的样式块列表
  var styles = []
  parts.style.forEach((item, index) => {
    //  只要样式块上定义了 theme 属性，就会对它进行操作
    let themed = getAttribute(item, themeKey) !== undefined
    if (!themed || !isLangSass(item.lang)) {
      styles.push(item)
    } else {
      Object.keys(themes).forEach((themeName) => {
        styles.push(wrapStyleWithTheme(item, themeName, themes[themeName]))
      })
    }
  })

  var styleString = restoreSections('style', styles)
  var templateString = restoreSections('template', parts.template)
  var scriptString = restoreSections('script', parts.script)
  output = `${templateString}\n${scriptString}\n${styleString}`
  return output
}
```

文件中的 parse 实际上来自于 `vue-loader` 的解析方法，作用是把 `vue` 文件内容拆成代码块、样式块和模版块。通过 loader 参数 theme 来传递主题列表，并插入变量文件：

```javascript
  {
    test: /\.vue$/,
    loader: 'vue-theme-loader',
    query: {
      theme: {
        dark: '@import "~$scss/theme/dark.scss";',
        light: '@import "~$scss/theme/light.scss";'
      }
    }
  }
```

虽然这个 `vue-theme-loader` 并没有在生产中投入使用，但是也给我们提供了一种解决问题的思路：通过自定义 `loader` 来改变源代码内容，做资源转换，在特定的情况下提供便利和可能。