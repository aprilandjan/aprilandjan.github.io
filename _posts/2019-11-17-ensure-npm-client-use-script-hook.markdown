---
layout: post
title:  使用钩子命令检查 npm 客户端
link:   ensure-npm-client-use-script-hook
date:   2019-11-17 20:20:00 +0800
categories: npm
---

在使用 `npm` 安装一个新的依赖时，`npm` 总是会默认的查找该模块已发布的最新的稳定版本，并写入到项目的 `package.json` 文件中；另外也总是会通过版本标注符 `^` 声明满足该版本约束（在当前主版本下大于或等于该版本号的所有版本）都是可接受的。这种默认的行为带来了一些问题。例如，某项目的 `package.json` 有如下的依赖声明：

```json
{
  "dependency": {
    "react": "^15.4.3"
  }
}
```

当一个项目开发者克隆该项目并进行安装时，可能此时 `react` 的最新稳定版已经是 `v15.4.9` 了，因为它满足 `npm` 的 [semver](https://docs.npmjs.com/misc/semver) 规范，那么此人实际安装的版本就将会是 `v15.4.9`。

然而项目可能要求必须要在版本 `v15.4.3` 时才完全和预期没有差异；同理，其他的模块依赖，以及依赖的依赖，都可能因为模块版本的变更出现差异。这种差异累积起来，甚至有可能会导致项目尽管安装完全正确，但是在新的环境中甚至无法顺利运行。毕竟在 `npm` 的生态里，模块彼此依赖，很难保证每个模块都能完全的遵循语意化版本，做到大版本号间的向下兼容。

## 版本锁文件

为了解决以上问题，`版本锁` 文件应运而生了。它明确的声明了项目每个模块的实际使用版本、获取地址、依赖的依赖关系等，并且在下次安装时直接根据该版本锁文件去获取依赖及组织 `node_modules` 内的文件结构，既保证了项目在不同环境下依赖安装的一致性，又提高了安装速度。

如果使用 `yarn` 安装依赖，`yarn` 会生成 `yarn.lock` 文件作为其所识别的版本锁文件；而 `npm` 则使用 `package-lock.json` 作为版本锁文件。它们彼此格式和解析各不相同，无法互相识别、混用。

## npm 客户端的差异

在实际的多人协作项目中，经常遇到这种问题：不同成员使用的 npm 客户端不同，有人习惯用 `npm`，有人习惯用 `yarn`；他们参与到项目进行安装时，常有人不注意当前项目的 lock 文件设置，直接使用自己熟悉的 npm 客户端，导致安装的模块版本出现差异，致使项目无法运行，或者出现某些匪夷所思的状况。

当然，可以通过项目文档、口口相传的方式去尽量明确告诉开发者应该使用什么，但从项目工程化的角度上来说，通过特定的钩子脚本去检查、确保开发者的使用工具，从一开始就杜绝潜在的错误，会更加可靠。

## npm 钩子命令

`npm` 拥有以下的钩子命令：对于任何在 `package.json` 的 `scripts` 字段中定义的命令，可以通过 `pre` 以及 `post` 名称前缀，额外定义该任务在执行前、后的额外执行的钩子命令。例如：

```json
{
  "scripts": {
    "premy-task":  "echo 'task begin...'",
    "my-task": "node my-task.js",
    "postmy-task": "echo 'task completed!'"
  }
}
```

`my-task` 是某个目标命令名；在使用 `npm` 或 `yarn` 执行该命令（`npm run my-task` 或者是 `yarn my-task`）时，总是会自动的先去查找该命令是否有 `pre` 命令（即 `premy-task`），如果有就先执行该先决命令，且成功后再执行原命令 `my-task`；如果此命令成功结束了，总是会自动的去查找该任务是否有 `post` 命令（即 `postmy-task`），如果有就执行该后续命令。这种钩子命令，同样也能作用于一些 npm 客户端自身的行为，例如 `install`，`uninstall` 等。

于是，我们可以尝试用钩子命令来解决以上的 npm 客户端差异的问题，对用户当前使用的 `npm` 客户端进行预检：如果当前启动命令的是不合适的 npm 客户端，提前给出提示并抛出错误、中止后续行为。

## 判定当前的 npm 客户端

现在执行检查的时机有了，我们还需要实现检查的逻辑。如何判定当前的程序是通过哪种 npm 客户端调起的呢？

最直接的想法是通过进程信息去查找。我们知道，js 文件实际上是通过 `node` 可执行程序解释执行的，无论是 `npm` 还是 `yarn`，它们实际上都是 js 文件在被 node 执行，那么，用当前的进程的调用目标和参数，判断当前可执行文件，似乎也是可行的了。

在 node 里，可以通过全局对象 `process.args` 获取当前进程的参数列表。参数列表的第一位总是指向当前的调用目标，随后的参数则可能依次是文件等信息。现在假设我们在项目里通过 `preinstall` 钩子执行一段检查的 js:

```json
{
  "scripts": {
    "preinstall": "node ./check.js"
  }
}
```

那么通过 npm 命令钩子执行 `check.js` 时，当前的进程参数表，总是得到 `node` 程序路径以及 js 文件路径，似乎没有是否是 `npm` 或 `yarn` 的信息。但是没关系，既然当前进程没有，它总归是由某个来自 `npm` 或 `yarn` 的进程所开辟的子进程所执行的。如果通过查找当前进程的父进程的方式，依次找下去，总会找到一个进程的信息它通过 `node` 执行了来自于 `npm` 或 `yarn` 的脚本。于是问题来到了怎样去递归的查找当前进程的父进程及其进程参数的问题。`process` 拥有 `pid` 以及 `ppid` 来指代当前进程的 id 及父进程 id, 但是遇到递归向上查找时，并没有一个内置的方法去查找。所幸万能的 npm 生态里无所不包，可以通过 [find-process](https://github.com/yibn2008/find-process) 兼容的查找指定进程可能的一切信息，包括父进程 id, 参数列表等等。于是通过这个工具，不难实现判断当前程序是否是最终通过 `npm` 或 `yarn` 唤起的逻辑。

虽然这样操作具有可行性，但是总归不太方便。能不能有其他的方式呢？npm 客户端会在执行时往进程里写入许多关于当前程序的环境变量，这里面有没有可以利用的信息呢？尝试使用 `npm` 和 `yarn` 分别执行了一段命令，并且把进程的全部环境变量打印出来做对比：

```javascript
const fs = require('fs');
fs.writeFileSync(`env-${Date.now()}.json`, JSON.stringify(process.env, null, 2));
```

可以从中发现，无论是 `npm` 还是 `yarn`，它们都会通过环境变量 `npm_config_user_agent` 写入当前的客户端信息——这有点类似于浏览器的 `navigator.userAgent`。例如：

```javascript
//  when executed by yarn, for example: 'yarn/1.7.0 npm/? node/v8.9.4 darwin x64'
//  when executed by npm, for example: 'npm/6.1.0 node/v8.9.4 darwin x64'
console.log(process.env.npm_config_user_agent);
```

于是，用这个信息来判断 npm 客户端，就非常简单直接了。可以在 `check.js` 里写上相应的判断代码，然后如果当前使用的 npm 客户端，则给出提示、抛出异常并避免执行后续任务。

## 在“安装模块“前执行检查程序

前面已经提到过，可以利用 `preinstall` 钩子命令去执行检查代码。但是经验证，还存在一些问题：`npm` 和 `yarn` 对待 `preinstall` 的调用时机不一致。`npm` 仅会在当前项目执行安装（即 `npm install`）时会触发该钩子调用，单独安装某个模块（即 `npm install <module>`）时并不会触发；而 `yarn` 则在这两种情况下都会触发该钩子命令。这样一来，如果想通过该钩子命令去限制 `npm` 的使用者，就无法达到预期效果了([issue](https://github.com/npm/cli/issues/481))。

## `check-npm-client`

基于以上的尝试和探索，我把相关的代码提炼为一个单独的模块 [check-npm-client](https://github.com/aprilandjan/check-npm-client)：它提供了对当前程序的所使用的 npm 客户端的判断，并可以通过预定义的 `bin` 脚本在项目中的钩子命令里直接使用。当然，因为上面分析的一些原因，对希望能限制 `npm` 来安装模块的情况下不能完全和预期一样，但也有一些别的方式或许可以绕过：`npm` 拥有一些区别于在 `package.json` 里定义的钩子命令的“[钩子命令](https://docs.npmjs.com/misc/scripts#hook-scripts)”，能实现对任意模块安装的钩子流程。或许可以利用独立模块的 `preinstall` 功能去写入这样的钩子，以实现和 `yarn` 相同的表现。不过，具体的实现就有待后续再去完善了。

## References

- <https://github.com/npm/cli/issues/481>
- <https://docs.npmjs.com/misc/scripts#hook-scripts>
