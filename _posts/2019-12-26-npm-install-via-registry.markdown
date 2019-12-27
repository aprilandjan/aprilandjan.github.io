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

网上也能搜索到一些声称该参数有用的说法，例如：

- <https://stackoverflow.com/questions/35622933/how-to-specify-registry-while-doing-npm-install-with-git-remote-url>
- <https://shapeshed.com/using-the-european-npm-mirror/>

但是真的有这个参数吗？查看了 `npm` 以及 `yarn` 的文档，都没有提到对该参数的支持。经测试，无论是 `npm` 还是 `yarn` 在安装模块时添加参数 `--registry` 都没有效果。可见这种方式是不可行的，不知道因为什么原因以讹传讹，让很多人以为可行。

## 参考

- <https://docs.npmjs.com/cli/install.html>
- <https://yarnpkg.com/lang/en/docs/cli/add/>
