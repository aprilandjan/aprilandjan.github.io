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

上面这串配置的含义是: 通过正则 `/\.css$/` 匹配输入资源，匹配到的资源（.css文件) 将会被 `loader` 中定义的 loader 序列处理。这里 loader 是一个从右到左的处理序列，用 `!` 分隔开。一份 `.css` 文件首先通过右侧第一个 loader 也就是 antd-local-icon 处理（并且附带上参数 url=/main/fonts/), 经它处理完之后，再依次交由后续的 `css-loader`、`style-loader` 处理并最终整合到应用代码中。`antd-local-icon` 就是自定义的 loader 了，下面是它的实现代码：

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

