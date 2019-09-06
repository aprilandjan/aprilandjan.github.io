---
layout: post
title:  npm 模块的版本冲突
link:   npm-dependency-version-conflict
date:   2019-09-06 20:36:00 +0800
categories: npm
---

在之前的文章里曾提到 npm 是如何处理依赖与依赖冲突的。这里的依赖冲突指的是某个模块的**不同版本**都被当前项目所需要所导致的可能的冗余。由于这种冗余情况不可避免的存在，可能会导致一些值得关注的问题。

## 指定的版本冲突

正如之前模拟依赖版本冲突中描述的，当项目的模块树下有不同分支节点对某模块有指定的版本要求时，会发生版本冲突：

```bash
root
└── node_modules
    ├── A@1.0.0
    │   └── node_modules
    │       ├── C@1.0.0
    │       └── D@1.0.0
    └── B@2.1.0
        └── node_modules
            ├── C@2.0.0
            └── E@2.0.0
```

上例中，模块 `C` 的两个版本 `v1.0.0` 以及 `v2.0.0` 均会被引入从而发生因指定版本而造成的冲突。

## 非指定的版本冲突

在 npm 的 `package.json` 里，也能通过特定的[语义化版本规则](https://docs.npmjs.com/misc/semver)指定项目可接受的依赖 `版本范围`，例如：

```json
{
  "dependencies": {
    "module-a": "3.2.4",
    "module-b": "^2.5.0",
    "module-c": "<0.9.0",
  }
}
```

在上例中，`module-a` 明确指定了需要版本 `v3.2.4`；`module-b` 则通过前缀字符 `^` 指定了范围版本范围 `>=2.5.0 <3.0.0`（参考[semver](https://docs.npmjs.com/misc/semver#caret-ranges-123-025-004)文档，`^` 的版本规则其实更加复杂）；而模块 `module-c` 则接收版本小于 `v0.9.0` 的全部情况。

上例中，假如 `module-c` 的依赖中包含 `module-b` 且其版本要求为 `<=2.0.0`，那么在安装时，`module-b` 也会发生版本冲突。

## 版本冲突的模块如何在运行时共存

## webpack 如何处理版本冲突的模块

## 参考

- <https://docs.npmjs.com/files/package.json#dependencies>
- <https://docs.npmjs.com/misc/semver>
