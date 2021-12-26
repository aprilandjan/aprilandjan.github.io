---
layout: post
title:  nodejs 中对文件路径的兼容处理
link: posix-path-in-nodejs
date:   2021-09-24 19:53:00 +0800
categories: nodejs
---

最近写的一些单测运行在某些流水线机器上莫名其妙的挂了。查看详情，发现是文件路径处理的方法的用例失败。例如，期望得到的路径是 `/path/to/file.txt`，实际拿到的路径却为 `\path\to\file.txt`，这是为什么呢？

## `path` 模块

通常，我们使用 [path](https://nodejs.org/api/path.html) 模块去处理文件路径的相关操作，例如：

```js
const path = require('path');
const relativePath = './image/city.png';
console.log(path.join(__dirname, relativePath));
```

以上代码基于当前文件的路径 `__dirname` 打印出某个相对路径文件的绝对路径地址。现尝试在 windows/mac 中分别执行，看看结果会有什么区别。

在 `windows` 系统中：

```js
// __dirname = D:\my\folder
const path = require('path');
const relativePath = './image/city.png';
console.log(path.join(__dirname, relativePath)); // D:\my\folder\image\city.png
```

在 `mac` 系统中：

```js
// __dirname = /my/folder
const path = require('path');
const relativePath = './image/city.png';
console.log(path.join(__dirname, relativePath)); // /my/folder/image/city.png
```

可见，同样的代码，由于系统路径规则的差异，导致结果形式也存在区别。`mac` 系统中采用 `/` 字符作为路径段落分隔符(path segment separator)，而 `windows` 系统中，通常采用 `\` 字符（注：该字符在字符串中构造书写时，需要转义写为 `\\`，例如 `const p = '\\path\\to\\file'`）作为路径段落分隔符。

## `path.posix` & `path.win32`

### `fs.exists` 是否能兼容识别不同形式的文件路径？

- 在 windows 系统中，`fs` 相关 API 可以使用 `.\\path\\to\\file` `./path/to/file` 两种形式的路径；

### 浏览器(chrome)是否能兼容识别不同形式的文件路径？

- 在 windows 系统中，浏览器可以打开 `D:\\my\\folder\\image\\city.png` 或者 `D:/my/folder/image/city.png` 两种形式的路径（且浏览器会自动转换为 posix 的文件路径格式）；

### windows 文件浏览器中，是否能兼容识别 posix 形式的文件路径？

- 在 windows 文件浏览器中，可以识别 `D:\\my\\folder\\image\\city.png` 或者 `D:/my/folder/image/city.png` 两种形式的路径（且文件浏览器会自动转换为 windows 的文件路径格式）；

### 如何将 win32 路径与 posix 路径互相转换？

## References

- <https://nodejs.org/api/path.html>