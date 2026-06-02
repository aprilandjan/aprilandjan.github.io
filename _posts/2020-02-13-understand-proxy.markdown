---
layout: post
title:  understand proxy
link: understand-proxy
date:   2020-02-13 23:43:00 +0800
categories: os
---

由于疫情影响，很多公司最近都推行远程办公。但是很多业务是需要能接入公司内部网络才能开展的，为了能让天南海北的人用自己的网络访问公司的内网，想必大家是没有少接触各种“代理”软件的。即便接入了某些代理软件，可能还是有一些特殊的网络服务无法访问，情况会比较复杂。本着解决问题的精神，还是有必要了解下各种代理的方式和基本原理。

## proxy server

所谓代理，意即用户 A 将网络流量先发送到某个特殊的服务器 B，该服务器 B 再去获取目标网络资源 C，并将资源 C 返还给当前用户 A。在这个过程中，A 可能由于防火墙限制或者其他的网络隔离手段，直接无法访问到 C，但是服务器 B 具有与用户A、服务器 C 的互通访问权限，这样服务器 B 就起到了一个请求的“中间代理人”的角色，所以又称为代理服务器。

假设用户 A 要自行实现这种访问资源 C 的代理服务 B，那应该要怎么做呢？

首先要考虑的是：A 到 C 的资源请求要怎样才能通过 B。最简单的，A 虽然是想去取得 C 的资源，但是请求还是直接发往 B，B 在接收到请求后，将请求的内容（包括 url, headers, payload 等）组装为 B 向 C 发起的请求，并把拿到结果返回给 A。即便在 https 的情况下，由于加密发生在传输层，而代理产生的过程都在上层业务中实现，和加密传输的过程无关，因此不会有什么影响。

但是，这种代理也有明显的缺点，例如登录认证的场景下，假如 C 通过响应头 `set-cookie` 设置了带有 `domain` 限制的 `cookies` 作为用户凭证，那么如果 B 不对响应做一定的加工处理，A 在拿到响应资源时就可能就会因为 `domain` 无法匹配而认证失败。在前端开发中，通常在本地启动的用于托管本地资源、开发调试的服务器就是这样一个代理服务器，通过一定的配置，可以使之代理第三方服务器接口的访问。例如：

1. A 实际需要访问的 C 的资源是 `https://server-c.com/res/c.html`
2. A 转而访问代理服务器 B， 形如 `https://server-b.com/proxy?target=https://server-c.com/res/c.html`
3. B 解析请求参数，得知 A 想要获取的资源是 `https://server-c.com/res/c.html`
4. B 以 A 携带的请求参数访问 C 资源，且在获取后返还给 A
5. A 成功获取到想要的 C 的资源

但很多时候，当 A 访问资源 C 时，并不会显式的转向代理服务器 B，客观条件也不允许这样做。那应该要如何实现代理呢？

## `http_proxy`, `https_proxy` and `no_proxy`

在 linux 系统中，可以通过环境变量 `http_proxy`/`https_proxy` 设置 http/https 协议的请求要发往的代理服务器地址，例如：

```bash
export http_proxy=http://my-proxy-server.com:port
export https_proxy=https://my-proxy-server.com:port
```

也可以通过环境变量 `no_proxy` 指定不经过代理服务器的资源地址，例如：

```bash
export no_proxy=localhost,127.0.0.1,.example.com
```

设置后，几乎所有的系统自带的命令行工具例如 `wget`, `curl`, `ssh`, `apt-get` 等都将按照代理规则进行相应协议的访问。其他的软件或程序可能并不会应用该环境变量配置并进行代理访问，例如 `node.js` 中的 `net` 模块等。所以，`node.js` 中通常需要使用 [global-agent](https://www.npmjs.com/package/global-agent) 帮助程序应用全局代理设定：

```bash
$ export GLOBAL_AGENT_HTTP_PROXY=http://my-proxy-server.com:port
$ node -r 'global-agent/bootstrap' my-script.js
```

## 系统代理

在 Windows 系统中，使用某些三方代理软件时，你可能会注意到有这个“系统代理”选项：

![windows-system-proxy](/img/2020-02-13-understand-proxy-windows-system-proxy.png)

勾选该“系统代理”后，代理软件实际上会修改系统的设定。可以通过“开始”->“设置”->“网络和Internet”-->“代理”中查看具体配置：

![windows-system-proxy-2](/img/2020-02-13-understand-proxy-windows-system-proxy-2.png)

可能你也遇到过，即便勾选了该“系统代理”，通过 ssh 进行 git 操作，依然还是会报网络不通。事实上，这个“系统代理”接管的仅仅是 http/https 流量，而不是所有流量！所以，Windows 系统设置的代理设置其实只是 http/https代理，而不是真正意义上的全局代理。

值得一提的是，假如代理软件意外退出了，它将很有可能来不及还原其启动时修改的系统代理设定。此时，系统依然尝试通过代理软件提供的本地代理服务器去访问资源，结果自然会是访问失败了。例如，chrome 在此时会报告“代理服务器出现问题”：

![chrome-proxy-failed](/img/2020-02-13-understand-proxy-chrome-proxy-failed.png)

解决方式也很简单，重开一下代理软件，再手动操作其退出；或者是手动通过系统控制面板关掉“使用代理服务器”选项即可。

## PAC

在浏览器中，也可以通过配置 PAC(Proxy Auto-Configuration) 文件控制特定请求是否通过代理服务器。PAC 文件由实际上是服务器托管的一段特殊的 javascript 编写的代码文件，在该文件中可以通过调用预置的方法，并编写资源匹配规则，以决定如何（直接访问还是通过代理服务器）获取资源。例如：

```javascript
// This PAC file only proxies what is in proxy_list
function FindProxyForURL(url, host) {
    // Variables defined for Proxy=Yes and Proxy=No
    var proxy_yes = "PROXY my-proxy-server:port";
    var proxy_no = "DIRECT";
    // List of all domains you want to Proxy
    var proxy_list = Array(
        "*.google.com/*",
        "*.youtube.com/*",
        "*.yahoo.com/*",
        "*.bing.com/*"
    );

    for(var iter = 0; iter < proxy_list.length; ++iter) {
        if(shExpMatch(url, proxy_list[iter])) {
            return proxy_yes;
        }
    }

    // DEFAULT RULE: All other traffic, send direct.
    return proxy_no;
}
```

通常该 PAC 文件需要由某个服务器托管（来自网络服务器的地址，或者是本地服务器自行托管的地址）。各大浏览器都可以配置使用的 PAC 地址，具体操作步骤本文中不再赘述。
