---
layout: post
title:  注入当前的 npm 包版本信息
link:   bundle-current-npm-package-version
date:   2019-09-16 20:57:00 +0800
categories: npm
---

很多场景下，需要往代码里注入当前项目的版本号。最简单的，可以通过以下方式获取到：

```javascript
export const version = require('./package.json').version;
```

这样虽然可行，但是考虑到需要打包的场合（例如需要在前端页面中获取并显示，或者是输出纯粹精简的模块文件），由于实际上会引入整个 `package.json`，会导致信息泄漏与冗余。例如，`webpack` 在遇到
`require('./package.json')` 时，会把完整的 `package.json` 打包到目标文件中，而实际上，我们只希望写入一个版本号。

## webpack.DefinePlugin

webpack 自带的插件 `DefinePlugin` 可以通过定义替换字符串的方式实现这个目标。具体来说，在构建时通过以上方式获取 `version`, 再通过 `DefinePlugin` 声明将构建目标文件中的特定的字符串（往往是环境变量的形式）查找替换为该值：

```javascript
// in webpack config, add this plugin
new webpack.DefinePlugin({
  'process.env': JSON.stringify({
    VERSION: require('./package.json').version,
  }),
})

//...

//  in source codes, use this environment variable
export const version = process.env.VERSION;
```

## npm environments

其实，npm 在运行代码时也会默认的往当前运行环境中注入许多以 `npm_package_` 作为前缀的环境变量，例如：

- `npm_package_version`: 当前 npm 工程的 `package.json` 内定义的 `version` 字段值；
- `npm_package_name`: 当前 npm 工程的 `package.json` 内定义的 `name` 字段值；

这些环境变量能在运行时通过 `process.env` 直接访问，因此我们也可以在使用 `DefinePlugin` 时直接使用 `process.env.npm_package_version`：

```javascript
// in webpack config, add this plugin
new webpack.DefinePlugin({
  'process.env': JSON.stringify({
    VERSION: process.env.npm_package_version,
  }),
})

//...

//  in source codes, use this environment variable
export const version = process.env.VERSION;
```

## 参考

- <https://docs.npmjs.com/misc/scripts#packagejson-vars>
