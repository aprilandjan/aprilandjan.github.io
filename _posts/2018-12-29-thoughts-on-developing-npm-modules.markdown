---
layout: post
title:  npm 模块开发漫谈
link:   thoughts-on-developing-npm-modules
date:   2018-12-29 23:40:00 +0800
categories: npm
---

开发一个 npm 模块前，通常需考虑以下几个问题：

- 使用环境是在浏览器端还是 node？
- 用到了哪些语法特性？
- 是否需要编译为兼容性更好的语言版本？
- 是否使用 babel/typescript?
- 是否需要把零散的源代码文件打包成一个单独的文件？
- 哪些文件需要提供给模块使用者？
- 如何引入及管理模块自身的依赖？

接下来我们将逐个讨论这些问题。

### 使用环境是在浏览器端还是 node？

两者主要区别还在于浏览器端和 node 端能访问到的 api 不同。浏览器端主要是对页面做操作，而 node 端则囊括文件读写、数据存取、网络服务等。比如，浏览器端能访问 `window` `document` 等 node 中不存在的对象，而 node 端能使用 `global` `process` 等浏览器中不存在的对象。如果没弄清楚环境随意使用，可能会产生 undefined 异常。

如果代码既可能运行在 node 中，也可能运行在浏览器里，该代码就可称之为同构的(isomorphic)。此时尤其需要考虑对不同环境 api 的调用是否合理。

### 用到了哪些语法特性？

这里主要是指的是 ES6 及以上的一些高级语法特性在目标环境上是否兼容。例如，一段在浏览器环中运行的 JS 代码里，如果使用了箭头函数 `() => {}`, 那么在 IE 系列的浏览器中就会报错，因为 IE 浏览器全系不支持该语法([reference](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Arrow_functions#Browser_compatibility))；又例如，一段在 node 端运行的代码里，使用了异步函数 `async` `await`, 那么它在node v7.6 以下的版本中运行时候就会报错，因为 node v7.6 才开始源生支持异步函数语法。

### 是否需要编译为兼容性更好的语言版本？

为了避免或者减少语法特性的兼容问题，一般有两种策略：

1. 使用语法转换器(transpiler) 把自己的源代码转换为更兼容的代码。常用的转换器有 `babel` `typescript` 等；
2. 在目标环境添加语法兼容代码(polyfill)，提供新语法特性里加入的 api。这种方式需要模块使用者自行添加。常用的 polyfill 有 [babel-polyfill](https://babeljs.io/docs/en/babel-polyfill)、[core-js](https://github.com/zloirock/core-js) 等。

polyfill 并非万能良药。某些语法特性关键字、部分 api(例如 ES6 Proxy) 无法被 polyfill。另外作为模块开发者，我们无法干预目标环境，因此使用语法转换器编译在大部分情况下就很有必要了。

### 是否使用 babel/typescript?

如果清晰的了解代码中使用的特性以及目标环境，可以不使用语法转换器，免去不必要的配置。但如果决定要使用 babel/typesript 编写源码, 我还是推荐各位使用 typescript, 原因如下：

1. 配置简单。只需要安装 `typescript` 这一个模块，结合 `tsconfig`，就能够满足各种语法需求和输出环境设定；
2. 对开发者友好。拥有类型定义及类型推断，在开发时就能避免大量潜在错误；
3. 对使用者友好。能自动生成源代码的类型定义文件 `.d.ts`，如果使用者的 IDE 对 `typescript` 支持良好(例如 VSCode) 或者处于 `typescript` 开发环境中，类型支持会极大改善使用体验。

### 是否需要把零散的源代码文件打包成一个单独的文件？

可能绝大部分情况下，模块开发者都没有必要把源代码打包到一个单独的文件中。如果模块在 node 端使用，鉴于 node 所使用的 CommonJS 规范对模块作用良好的引用及隔离，没必要打包；如果模块在浏览器端使用，倘若使用者是通过 `webpack` 或者其他的打包工具引入模块，那么源代码中的零散文件一样会被打包工具索引并引入，也无需打包。打包通常伴随着代码压缩混淆，如果没有提供 sourcemap, 在开发调试时反而不方便。

仅当模块需要提供一份单独的文件供使用者直接使用（比如前端模块需要打包成一个可以直接放在浏览器 script 标签中加载的完整文件）时，才需要打包。使用 webpack/rollup 之类的工具把所有源代码整合成一个独立运行单元，需注意是否把其他无需打包的依赖模块也整合进去而导致包体积过大；针对不同的使用环境(目前多是 CommonJS 或者UMD)，打包目标是否设置合适。

### 哪些文件需要提供给模块使用者？

假设现在使用 typescript 开发某模块，源代码目录在 `./src`，编译输出的目录在 `./dist`，项目目录如下:

```
root
├── node_modules
│   └── ...
├── src
│   └── index.ts
├── dist
│   ├── index.js
│   └── index.d.ts
├── package.json
├── yarn.lock
├── .npmrc
├── .gitignore
├── README.md
└── CHANGELOG.md
```

以上文件中，由于 `dist` 目录是经由源代码编译输出生成，它没有必要放在代码仓库(git)中，因此需要在 `.gitignore` 中忽略掉；但是发布到 npm 时，模块的使用者只需要使用编译后的文件，而源代码 `src` 是无用的，因此 `dist` 目录应该保存，而 `src` 目录应排除。另外，模块锁文件 `yarn.lock` 或者 `package-lock.json` 以及其它使用者不关心的文件都应排除。

可以通过 `.npmignore` 文件指定这种发布模块忽略策略。默认的，如果模块没有定义 `.npmignore`, npm 默认会采用与目录中 `.gitignore` 相同的规则忽略文件；同时 npm 也隐式的忽略掉了诸如 `.npmrc` `.git` 等文件。具体规则可以参考 [npm 文档](https://docs.npmjs.com/misc/developers#keeping-files-out-of-your-package)。

### 如何引入及管理模块自身的依赖？

当需要在自己开发的模块中引入其他模块依赖时，可以简单的通过 `npm install <dep>` 来添加。但是需要注意，`package.json` 支持三种类型的依赖：

1. `dependency` 是模块要能正常工作所必须的依赖。使用者安装模块时，这些模块也会被自动安装；
2. `devDependency` 是在开发此模块过程中的依赖。使用者安装模块时，无需安装这些模块；
3. `peerDependency` 也是模块要能正常工作所必须的依赖，但是使用者安装模块时，这些模块不会被自动安装，仅在安装完成后才检查当前工程内此依赖是否已经被其他模块所安装。例如，为 `vue` 框架开发了某个组件并提炼为单独的模块，使用该组件时，一定要搭配 `vue` 框架；通常 `vue` 已经被使用者单独安装过了，组件模块自身无需安装 `vue`，这时把 `vue` 声明为组件模块的 `peerDependency` 就比较合适。

明白了以上的区别，在为模块添加依赖时就能分辨它们的地位，为用户节约流量，提高安装速度。

## 开发调试技巧

在开发模块时，通常需要一定方式来开发调试，提高效率。以下是我的一些理解供参考：

### 调试信息输出

一段代码最快的调试方式莫过于使用 `console.log` 打印出关键信息。但是往往发布出去面向用户后，不再需要这些打印的信息干扰用户的控制台输出。可以自己动手对 `console.log` 包装一层方法，只在开发环境或者设置特定条件下才产生输出；或者更方便的，使用 [debug](https://github.com/visionmedia/debug) 输出调试信息，这样也便于使用者对输出信息分类观察、调试。

### watch & compile & reload

如果使用了 babel/typescript 编写代码或者 webpack 打包，因为都需要对源代码做处理才能运行使用，因此需要一种方式去监听源代码的变更，并重新编译。

`babel` `typescript` 以及 `webpack` 都提供了 `--watch` 选项以实现以上功能。但有时即便代码重新生成了，运行的开发程序可能也无法更新。可以另行使用 [nodemon](https://github.com/remy/nodemon) 之类的工具来监听并重新启动。

### 单元测试

代码功能是否可靠，没有必要一定要写一个完整可运行例子，或下载下来在真实环境使用了才知道。可以通过编写合适的单元测试代码来快速验证小块功能或是大段代码的逻辑输出是否符合预期。另外值得一提的是，单元测试鉴于其执行的独立性，对于打断点调试来说也是非常方便。推荐使用 [Jest](https://github.com/facebook/jest) 配合 VSCode 的 [Launch Script](https://code.visualstudio.com/docs/editor/tasks) 运行测试文件，事半功倍：

```json name=.vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Jest All",
      "program": "${workspaceFolder}/node_modules/.bin/jest",
      "args": ["--runInBand"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen",
      "windows": {
        "program": "${workspaceFolder}/node_modules/jest/bin/jest",
      }
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Jest Current File",
      "program": "${workspaceFolder}/node_modules/.bin/jest",
      "args": ["${relativeFile}"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen",
      "windows": {
        "program": "${workspaceFolder}/node_modules/jest/bin/jest",
      }
    }
  ]
}
```

### Link

因为各种原因，可能仍需要在其他项目中调试使用正在开发的某个模块。可以使用 [link](https://docs.npmjs.com/cli/link) 功能创建模块目录软链。首先在开发的模块目录中，通过命令 `yarn link` 链接该模块；再到其他项目目录中使用命令 `yarn link <my-module>` 中链接到该模块。这样一来即可实时修改源模块，并实时在其他项目中使用模块。

注意，调试完毕可能需要先清除掉这种链接关系：`yarn unlink <my-module>`, 再按需要真正的添加模块到项目依赖中。

### 预发布脚本

[npm scripts](https://docs.npmjs.com/misc/scripts) 其实预置了相当多种钩子命令，这些命令就好比 react/vue 组件的生命周期方法，如果在 `package.json` 里有定义对应的钩子命令，就会在相应动作触发时去执行自定义的某些行为。

作为模块开发者，当发布模块 `yarn publish` 前，往往需要做一些单元测试、清理、编译、打包等的工作。这时我们可以通过定义 `prepublishOnly` 钩子命令来确保发布前这些流程总是依次执行并且是通过了的。例如：

```json
{
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "test": "jest",
    "prepublishOnly": "test && rimraf dist && build"
  }
}
```

这样在发布前，总是会依次执行跑测试(test), 清理目录(rimraf dist), 以及编译(build) 的工作，确保流程正确。

## 参考链接

- <https://docs.npmjs.com/cli-documentation/>
- <https://docs.npmjs.com/misc/developers>
- <https://github.com/Microsoft/vscode-recipes>
- <https://docs.gitlab.com/ee/user/project/pages/>
