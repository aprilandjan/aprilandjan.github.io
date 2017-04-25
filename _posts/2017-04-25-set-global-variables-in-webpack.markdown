---
layout: post
title:  set global variables in webpack
date:   2017-04-25 17:33:00 +0800
categories: git
---

以下简介在 webpack 中定义、使用全局变量的方法。

### 定义想要全局调用模块 `test`

模块按照 `CommonJS` 的格式导出:

`test.js`:

```javascript
module.exports = {
  log () {
    console.log('test called!')
  }
}
```

### 配置 webpack

首先要给想要全局使用的模块定义别名，无论是自定义的模块，还是来自依赖里的模块都是可以的；再使用 webpack 自带的 `ProvidePlugin` 把模块放在全局使用。

`webpack.config.js`:

```javascript
var webpack = require('webpack')
var path = require('path')

// ...

module.exports = {
  resolve: {
    extensions: ['', '.js'],
    alias: {
      '$test': path.resolve(__dirname, '../src/utils/test.js')
    }
  },

  // ...
  
  plugins: {
    new webpack.ProvidePlugin({
      'test': '$test'
    })
  }
}
```

### 配置 `eslint.rc`

如果项目配置了 eslint 语法规范检查，很有可能会报语法规范错误 `error  "test" is not defined  no-undef`. 这是因为语法检查判断该变量没有定义或引入。解决办法是配置 `eslint.rc` 文件, 添加全局变量：

`eslint.rc`:

```javascript
module.exports = {
  
  // ..
  
  "globals": {
    "test": true
  }
}
```