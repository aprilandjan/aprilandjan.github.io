---
layout: post
title:  Cookie 安全标志
link:   cookie-security-flags
date:   2019-04-09 20:06:00 +0800
categories: http node
---

在中后台的前端系统中，通常使用 cookie 来存储用户登陆凭证。Cookie 是一小段通常由服务端通过 `set-cookie` 响应头设置、由客户端（通常指浏览器）自动解析并存储的数据块。在浏览器里，当打开页面请求资源时，默认地会通过请求头 `Cookie` 携带当前域下的有效 cookie 数据发送到服务器；服务器在收到请求后，通过该请求头的内容确定当前访问者的身份，并给出不同的响应。

由于 http 协议是无状态的，因此 cookie 成为了服务端鉴别客户端身份的重要途径。假如客户端的 cookie 值通过某些方式例如 [XSS](https://developer.mozilla.org/zh-CN/docs/Glossary/Cross-site_scripting) 被窃取或恶意使用了，就有可能造成用户数据泄漏等安全隐患。因此，服务端在 `set-cookie` 时，也往往需要使用安全标志提高客户端 cookie 的安全性。

## HttpOnly

`HttpOnly` 标识该 cookie 仅用于 http 传输，无法在客户端通过 javascript 代码直接读取。未标识为 `HttpOnly` 的 cookie，可以通过 `document.cookie` 直接访问到，因此客户端一旦被 XSS 注入恶意脚本时，恶意脚本能直接窃取到 cookie 造成凭证泄露。因此，如果客户端不需要自行解析 cookie 时，服务端通常应设置该标志位。

## Secure

`Secure` 标识该 cookie 仅随着 https 协议下的请求传输到服务器。由于 http 协议是未加密的，在 http 请求下携带 cookie 时，扮演中间人角色的网络服务提供商或者流量监控者能够明文查看位于请求头内的 cookie 信息——这也可能造成安全风险。因此，`Secure` 能很大程度的确保用户 cookie 不被中间人攻击所窃取。

对于服务器通过 `set-cookie` 请求头发送给客户端的 cookie 数据，即便服务端已标识了该 cookie 为 `Secure` 例如：

```bash
Set-Cookie: secure_one=yes; Path=/; Expires=Tue, 09 Apr 2019 11:17:54 GMT; HttpOnly; Secure
```

`Secure` 标识有一定的缺陷。如果请求发生在非安全协议下，仍然有可能会被中间人攻击所截获——这是 secure 标示的固有缺陷。现代浏览器(Chrome 52+/Firefox 52+) 在非安全协议下收到这种 `set-cookie` 时，并不会存储该 cookie，因此 `set-cookie` 会失效。

## Cookie 本地代理

前端后端分离开发的时候，前端本地常使用 node 启动一个开发服务器（devServer)，用来提供页面服务、代理转发接口请求避免跨域等功能。对于 cookie 来说，它只是 http/https 协议中请求头或响应头中的一段数据。因此对于开发服务器，cookie 依附于接口转发，一般来说不会有问题。

但是如果接口服务器在 `set-cookie` 时设置了 `Secure` 标记，代理到本地的登陆凭证可能会遇到障碍。例如：

- 客户端发送登陆请求；
- 登陆请求成功，接口服务器通过响应头 `set-cookie` 尝试往客户端设置登陆凭证 cookie；
- devServer 中转该请求到本地开发环境前端例如 `http://localhost:8080`；
- 因为该登陆凭证 cookie 被设置为 `Secure`，它在非 https 的本地开发环境下，被浏览器抛弃，没有成功存储到本地；
- 本地其他请求始终拿不到登陆凭证，被接口服务器坚定为未登陆，请求失败。

既然知道了问题的关键在于 `Secure` 标志上，那么在不改动后端配置的情况下，如果能在 node devServer 层面上手动去掉该标志，就可以保证 cookie 在本地设置成功了。如果有配置过 node devServer，可能会记得最常用的代理中间件[http-proxy-middleware](https://github.com/chimurai/http-proxy-middleware) 的配置参数里有一项 `secure`——它能否直接在代理时去掉该 cookie 标识呢？参看文档：

> option.secure: true/false, if you want to verify the SSL Certs

原来，该配置参数来自模块 [http-proxy](https://github.com/nodejitsu/node-http-proxy)，它只是配置代理时是否验证 ssl 证书，并不是加工 cookie 去掉 `Secure` 标志。因此，参考 [issue](https://github.com/chimurai/http-proxy-middleware/issues/237)，我们只好在配置里监听代理事件，自行手动加工代理回来的响应了：

```javascript
const options = {
  onProxyRes: (proxyRes, req, res) => {
    const sc = proxyRes.headers['set-cookie'];
    if (Array.isArray(sc)) {
      proxyRes.headers['set-cookie'] = sc.map(sc => {
        return sc.split(';')
          .filter(v => v.trim().toLowerCase() !== 'secure')
          .join('; ')
      });
    }
  },
}
```

通过以上设定，我们成功的在本地开发环境下去掉了接口服务器的 cookie 安全标识，确保后续接口调用能正确携带登陆凭证。

## 参考链接

- <https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies>
- <https://stackoverflow.com/questions/21540089/why-do-browsers-accept-secure-cookies-sent-over-a-non-secure-http-connection>
- <https://github.com/chimurai/http-proxy-middleware>
- <https://github.com/chimurai/http-proxy-middleware/issues/169>
- <https://github.com/nodejitsu/node-http-proxy/issues/1165>