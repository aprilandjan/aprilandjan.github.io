---
layout: post
title:  webpack library starter
date:   2017-04-18 15:34:00 +0800
categories: javascript webpack babel
---

### 准备工作

目录结构如下：

    -- Project
        |-- lib                   //  打包之后的文件
        |-- src
            |-- index.js          //  js 入口
        |-- .babelrc              //  babel 配置文件
        |-- .gitignore
        |-- webpack.config.js     //  webpack 配置文件
        |-- package.json
        |-- readme.md


### webpack 配置

这里使用的是 `webpack2`，与 `webpack1` 没有太多不一样的地方，注意 `module.loaders` 变成了 `module.rules`。入口文件位于 `/src/index.js`，最终打包出来的文件放置在 `/lib` 目录下。

几个注意点：

- `output.libraryTarget`
  
  设置发布出来的模块类型。参考[文档](https://webpack.js.org/configuration/output/#output-librarytarget), 如果设置成 `umd`，打包出来的模块可以在各种类型的模块定义（CommonJS, AMD, 或者是没有模块的全局环境)下使用。例如：

  - `import MyLibrary from 'my-library'`
  - `var MyLibrary = require('my-library')`

- `externals`

  默认情况下，webpack 会把入口文件用到的全部依赖项都打包进来，包括第三方的模块依赖。这一部分是可以省略掉的，因为这些第三方的依赖由用户自己管理，没有必要重复整合在一起。例如：

  ```
  module.exports = {
      ...
      externals: {
          "lodash": {
              commonjs: "lodash",
              commonjs2: "lodash",
              amd: "lodash",
              root: "_"
          }
      }
      ...
  }
  ```

### `babel` 配置

之前用 vue 的脚手架工具创建项目也并未过多的关注 `babel` 配置，没有深究哪些是有用的，分别是做什么的。实际上，`babel` 搭配 `webpack` 运行起来，需要以下几个模块：

- `babel-core`

  这个模块是各种语法的管理集合。通过它可以把一段代码依照配置(preset)转换成编译后的版本。

- `babel-loader`

  在 webpack 里，相应的加载器是必不可少的。它告诉 webpack 当遇到特定文件时，要使用什么模块去处理文件内容。

- `babel-preset-env`

  这个模块相当于是 `babel` 语法配置的 `autoprefixer`, 它能根据条件输出需要的预设配置，自动设定编译时需要转换哪些语言特性。例如，如果环境已源生支持 `promise` 了，代码中的 `promise` 就可以免去转换了。这个模块也可以替换成别的一些预设模块或它们的组合，例如 `babel-preset-es2015` `babel-preset-stage-0` 等等。



