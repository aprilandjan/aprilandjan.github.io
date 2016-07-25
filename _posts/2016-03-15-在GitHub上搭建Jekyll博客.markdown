---
layout: post
title:  "在Github上搭建Jekyll博客"
date:   2016-03-15 15:30:06 +0800
categories: GitHub Jekyll
---

跟随官方文档一步步来即可。如果想要本地测试效果，需要搭建 ruby 环境。

- 使用命令 `jekyll new blogName` 来创建一个 jekyll 模板;
- 进入目录 `cd blogName`;
- 通过 `jekyll serve` 开启本地服务;
- 目录下 `_config.yml`文件内添加配置字段;
- 默认本地服务端口是4000, 可以通过在配置文件里添加字段 `port: 4321` 等自定义;
