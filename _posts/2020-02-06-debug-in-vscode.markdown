---
layout: post
title:  debug in vscode
link: debug-in-vscode
date:   2020-02-06 20:00:00 +0800
categories: js vscode
---

## 以调试模式启动 node 进程

启动 `node` 进程时，可以通过附加参数 `--inspect` 启动 `node` 进程对调试器客户端的监听。例如：

```bash
node ./my-script.js --inspect
```

默认地，该调试模式进程会监听 `127.0.0.1:9229`，并被赋予一个随机的 [UUID](https://tools.ietf.org/html/rfc4122)。调试器客户端——例如 `vscode` 内置的的调试器程序——需要明确的知道该这些信息并通过 `ws` 协议连接到该进程，例如：`ws://127.0.0.1:9229/0f2c936f-b1cd-4ac9-aab3-f63b0f33d55e`。

## 挂载调试器到特定的调试模式的 node 进程

已知某 `node` 进程以调试模式启动，如何针对性的挂载调试器到该进程呢？以下以 `vscode` 为例列举一些挂载调试器的便利方法。

### Auto Attach

`vscode` 提供了自动挂载调试器功能。该功能可以自动检测通过 `vscode` 集成的命令行窗口所启动的调试状态的 `node` 进程，并自动对该进程及其通过 `spawn`/`fork` 等方式唤起的调试状态子进程挂载调试器。

通过 <kbd>Cmd + P</kbd> 打开命令面板并输入 `> Debug: Toggle Auto Attach` 即可开启该功能。开启后，`vscode` 底部的状态栏会显示为 `Auto Attach: On`。

需要注意的是，该功能仅针对 `vscode` 集成的命令行窗口启动的 `node` 进程才生效，有一定的局限性。我们也可以通过 `vscode` 提供的 `launch scripts` 配置挂载调试器的更多方式方法。

### Pick Process

在项目下新建 `./vscode/launch.json` 文件并添加如下调试配置（或通过触发 suggestions 并选择 `Node.js: Attach To Process` 模版配置）：

```json
{
  "type": "node",
  "request": "attach",
  "name": "Attach by Process ID",
  "processId": "${command:PickProcess}",
  "skipFiles": [
    "<node_internals>/**"
  ]
}
```

当按 <kbd>F5</kbd> 执行时，`vscode` 会弹出进程选择下拉框。这时可以手动选择想要查看的进程以挂载调试器。

## 调试 webpack bundle

由于 `vscode` 调试器只支持 `inline-source-map` ([reference](https://code.visualstudio.com/docs/nodejs/nodejs-debugging#_source-maps))，因此如果需要对 `webpack` 等转换打包输出的内容进行调试，可能需要：

- 将 `webpack` 的配置项 `devtools` 设置为 `inline-source-map`；
- 使用 `vscode` 调试配置文件 `launch.json` 中的 `sourceMapPathOverrides` 去将 webpack 资源地址正确的覆盖映射为资源的实际地址；
- 或者，使用 `webpack` 的配置项 [output.devtoolModuleFilenameTemplate](https://webpack.js.org/configuration/output/#outputdevtoolmodulefilenametemplate) 使之生成指向真实资源地址的 sourcemap。

## 调试 Chrome 中运行的代码

在使用 Webpack 开发前端应用时，可以通过 Chrome Devtools 内置的 Source 面板打开相应的源文件，并进行断点调试。通过 `vscode` 插件 [vscode-chrome-debug]，也可以在 `vscode` 调试器中调试运行在 chrome 里的代码。和上面的配置方式类似，添加如下调试配置：

```json
{
  "type": "chrome",
  "request": "launch",
  "name": "Launch Chrome against localhost",
  "url": "http://localhost:8080",
  "webRoot": "${workspaceFolder}"
}
```

启动该调试任务时，会自动启动一个独立的 chrome 窗口，打开配置中的 `url` 地址，并通过 chrome 开发协议 (CDP) 连接到 `vscode` 调试器程序。该插件默认的帮我们处理了可能的资源地址映射，由 create-react-app 创建的项目基本基本可以直接连上。

如果不想单独启动一个额外的 chrome 窗口，也可以将调试器尝试附加到某个指定的 chrome 页面，例如：

```json
{
  "type": "chrome",
  "request": "attach",
  "name": "Attach Chrome against localhost",
  //  这种方式需要 chrome 已经允许开启了 debug port
  "port": 9222,
  "url": "http://localhost:8080",
  "webRoot": "${workspaceFolder}",
}
```

但是这种方式要求当前的 chrome 窗口已经开启了指定的调试端口，正常来说需要**彻底关掉** chrome，再通过特定启动参数启动 chrome。例如：

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
```

因此反而显得不太实用。

通常在开发前端页面应用时，我们在 `vscode` 里进行开发， 在 `chrome` 里查看页面，在需要对页面逻辑进行断点调试的时，便可用通过 chrome devtools 的源代码页签浏览源代码，以及在源代码上打断点调试程序。

## References

- <https://nodejs.org/de/docs/guides/debugging-getting-started/>
- <https://code.visualstudio.com/blogs/2018/07/12/introducing-logpoints-and-auto-attach>
- <https://code.visualstudio.com/docs/nodejs/nodejs-debugging>
- <https://code.visualstudio.com/docs/nodejs/debugging-recipes>
- <https://github.com/microsoft/vscode-chrome-debug>
