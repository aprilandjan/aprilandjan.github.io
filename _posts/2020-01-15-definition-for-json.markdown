---
layout: post
title:  Definition for JSON
link: definition-for-json
date:   2020-01-15 20:46:00 +0800
categories: javascript
---

在之前的文章中有提到过 `json` 这种数据格式有许多局限。例如：它不支持注释，它不能使用单引号，最后一个对象类型的属性不能有额外的逗号等。另外，编写 JSON 的时候也往往也缺乏对它的结构和字段的代码提示说明，在校验 JSON 的时候，也天然缺乏友好的校验信息——这种感觉就好像是用记事本写 `js` 代码一般，孤独又无助。

如果大家熟悉 `vscode`，应该会发现在 `vscode` 里打开 `package.json`，或者是 `vscode` 自己的配置文件 `launch.json` 以及 `settings.json` 等文件时，编辑器都能在输入时进行提示、校验，体验非常的好。那 `vscode` 是如何实现这种提示与校验的呢？

## references

- <https://json-schema.org/learn/getting-started-step-by-step.html>