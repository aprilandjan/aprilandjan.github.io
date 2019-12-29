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

## 正确的做法

那么应该如何设置安装时的源呢？

首先可以使用 [nrm]()。`nrm` 意即 npm registry manager(npm 源管理工具)，使用它可以方便的查看和全局切换使用各种源；另外，也支持添加自定义源名称及地址，这在需要使用私有源时会非常的方便。例如：

```bash
$ nrm ls
$ nrm add my-private http://some-private-registry.com
$ nrm use my-private
```

其次，也可以使用 npm 配置文件 `.npmrc`。当执行 `npm` 命令时 `npm` 总是会从当前工作目录向上查找 `.npmrc` 配置文件，并根据读取到的配置信息复合而成一份配置参数表应用到命令执行中。有鉴于此，通常可以在项目目录下添加一份 `.npmrc` 配置文件，甚至配置针对某私有域的模块采用特定的私有源。具体内容如下：

```
registry=https://some-registry.com
@scope:registry=https://scope-specific-registry.com
```

## 参考

- <https://docs.npmjs.com/cli/install.html>
- <https://yarnpkg.com/lang/en/docs/cli/add/>
