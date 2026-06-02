---
layout: post
title:  webpack with autoprefixer
date:   2016-11-29 10:30:00 +0800
categories: webpack
---

一直以来以为 css 自动加浏览器厂商前缀的功能是 vue 的工具提供的, 所以也没怎么注意写兼容性前缀。
最近做另一个页面的时候, 被反馈 flex 布局的地方没有效果。然而在 can i use 上, flex 的兼容已经不错了。这是为什么呢? 首先想到了兼容前缀。打开发布的css文件一看,果然是没有的。
于是立马想到了之前在 vue 项目中看到的一个 webpack 配置 autoprefixer, 以前没有留意过它是做什么的, 现在顾名思义, 应该就是用它来自动补全前缀的吧!

上网搜了下, 的确是这样的。autoprefixer 是 [`postcss`](https://github.com/postcss) 下的一个模块, 也可以配合 webpack、 sass 一起使用。下面是配置方法:

##### 安装模块依赖

需要安装 postcss, autoprefixer:

```
npm install --save-dev postcss autoprefixer
```

##### 写入 webpack 配置文件

配合 sass、ExtractTextPlugin 一并使用, 写入 webpack.config.js:

```javascript
//webpack.config.js
const autoprefixer = require('autoprefixer') 
module.exports = {
    ...
    postcss: [ autoprefixer({
        // browsers: ['last 2 versions']    //  这里可以根据需求写兼容的范围
      }) ]
    module: {
        loaders: [
            ... 
            {
                test: /\.scss$/,
                loader: ExtractTextPlugin.extract('style-loader', ['css-loader', 'postcss-loader', 'sass-loader'])
             }
        ]
    }
}
```

关于 loader 的配置, 幸好 github 上有类似的 [issue](https://github.com/postcss/postcss-loader/issues/42), 否则可能得花时间摸索了...