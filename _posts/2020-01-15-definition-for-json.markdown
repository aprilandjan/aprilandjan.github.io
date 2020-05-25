---
layout: post
title:  Definition for JSON
link: definition-for-json
date:   2020-01-15 20:46:00 +0800
categories: javascript
---

在之前的文章中有提到过 `json` 这种数据格式有许多局限。例如：它不支持注释，它不能使用单引号，最后一个对象类型的属性不能有额外的逗号等。另外，编写 JSON 的时候也往往也缺乏对它的结构和字段的代码提示说明；在校验 JSON 的时候，也天然缺乏友好的校验信息——这种感觉就好像是用记事本写 `js` 代码一般，孤独又无助。

如果大家熟悉 `vscode`，应该会发现在 `vscode` 里编辑 `package.json`，或者是 `vscode` 自己的配置文件 `launch.json` 以及 `settings.json` 等文件时，编辑器都能在输入时进行提示、校验，用户体验一级棒。那 `vscode` 是如何实现这种提示与校验的呢？

## JSON Schema

[JSON Schema](https://json-schema.org) 是一种用来描述 JSON 数据格式的 JSON 数据。它制定了一份标准规范，按照这个规范所编写的 JSON 描述文件，可以用来声明或校验 JSON 文件或对象。例如：

```json
{
  "properties": {
    "first": {
      "type": "string"
    },
    "last": {
      "type": "string"
    },
    "length": {
      "type": "integer",
      "description": "the length of the list"
    }
  }
}
```

上例中，`properties` 字段定义了目标 JSON 的以下属性 `first`, `last`, `length` 的值类型，以及相关的属性描述。当然，完整的 `JSON Schema` 标准里拥有丰富的描述 JSON 所需要的方式，例如有哪些字段、哪些是必填、描述说明、默认值等等，在此不深讨论。

## VS Code Intellisense

将以上文件在一个 `vscode` 工程内另存为 `list.schema.json`。当在 `vscode` 内编辑该 `.schema.json` 文件时，`vscode` 的代码提示已能便利的提示我们该如何写这个文件了。事实上，`vscode` 在遇到 `.schema.json` 文件时，已自动将其关联为 `JSON Schema` 文件。接下来我们尝试以下如何用它来给工程中的其他 JSON 文件例如 `list.json` 提供代码提示。目录结构如下：

```
project
└── src
    ├── list.json
    └── list.schema.json
```

但默认地，`vscode` 并不知道如何将自定义的 `.schema.json` 与特定的 `json` 文件关联起来约束。可以通过 `vscode` 的配置项 `json.schema` 来显式的配置这一关联关系：

```json
{
  "json.schemas": [
    {
      "fileMatch": [
        "./src/list.json",
      ],
      "url": "./src/list.schema.json"
    }
  ]
}
```

注意：`fileMatch` 内可以配置匹配的 glob pattern，但 `url` 只能配置当前项目目录下的确定的相对路径。

此时我们再回到 `list.json`，试着键入拥有描述的字段 `length`，代码提示如期的正常工作了。

## More

除了编辑器层面的代码提示，`JSON Schema` 是否有更强有力的运行时校验约束呢？答案是肯定的。[ajv](https://github.com/ajv-validator/ajv) 是一个采用该规范进行 JSON 数据校验的第三方类库，很多其他模块也依赖它对配置项等 JSON 信息做校验。

## references

- <https://joshuaavalon.io/intellisense-json-yaml-vs-code>
- <https://stackoverflow.com/questions/60322864/how-does-vscode-support-automatic-json-validation-using-https-schemastore-org>
- <https://json-schema.org/learn/getting-started-step-by-step.html>
- <http://schemastore.org/json/>
- <https://github.com/ajv-validator/ajv>
