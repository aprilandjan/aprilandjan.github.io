---
layout: post
title:  npm 安装模块时指定 registry
link:   npm-install-via-registry
date:   2019-12-26 21:08:00 +0800
categories: npm
---

在使用 npm 安装来自某些私有源的模块时，可能会尝试使用 `--registry` 参数：

```bash
$ npm install <package> --registry https://some-private-registry.com/
# yarn add <package> --registry https://some-private-registry.com/
```

但是真的有这个参数吗？查看了 `npm` 以及 `yarn` 的文档，都没有提到对该参数的支持。

那么如何恰当的在模块安装时指定使用什么源？

## 参考

- <https://docs.npmjs.com/cli/install.html>
- <https://yarnpkg.com/lang/en/docs/cli/add/>