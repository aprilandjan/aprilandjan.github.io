---
layout: post
title:  为 EventEmitter 增加事件与响应相匹配的类型约束
link: add-type-constraint-to-event-emitter-use-cases
date:   2023-02-05 16:39:00 +0800
categories: nodejs
---

## 先天类型缺陷的 EventEmitter

在 `node.js` 相关的开发中中，经常会使用 [events](https://nodejs.org/api/events.html) 模块提供的 `EventEmitter` 类作为事件驱动模式的事件中枢或基类，用以实现模块间的松散耦合。例如：

```ts
import { EventEmitter } from 'events';

// an 'EventEmitter' subclass **without** explicit event type constraint
class ServiceA extends EventEmitter {
    //...
}

const a = new ServiceA();

// correct event & callback
a.on('progress', (percent) => {
    console.log('progress', percent * 100 + '%');
});
a.on('error', (error) => {
    console.log('error', error.message, error.stack);
});

// unmatched event & callback
// typescript gives no error tips
a.on('progress', (percent) => {
  console.log('progress', percent.value + '%');
});
a.on('error', (error) => {
  console.log('error', error.msg);
});

// matched event & payload
a.emit('progress', 0.1);
a.emit('error', new Error('unavailable'));

// unmatched event & payload
// typescript gives no error tips
a.emit('process', {x: {y: {z: 100}}});
a.emit('error', null, {msg: 'bad'});
```

在 TS 开发环境中，由于 `EventEmitter` 的 `emit`、`on` 等方法具作为通用的事件发布订阅渠道，没有也不太可能针对具体业务约束收窄为匹配的上下文类型，以上代码不会报类型校验错误。但实际业务中，当发布不同的事件类别时，其携带的负载数据往往也具有不同的类型以匹配事件类别。作为类型强迫症患者，我们希望 TS 能够自动建立事件与响应相匹配的类型约束关系，即：

1. 发布 `process` 事件时，约束该事件必须要携带一个 `number` 类型的数据负载（即 `a.emit(‘process’, 0.5)`）；
2. 发布 `error` 事件时，约束该事件必须要携带一个 `Error` 类型的数据负载（即 `a.emit(‘error’, new Error(‘terrible’)`）；
3. 订阅 `process` 事件时，约束该事件回调可通过其参数取得类型为 `number` 的数据负载；
4. 订阅 `error` 事件时，约束该事件回调可通过其参数取得类型为 `Error` 的数据负载。

简而言之，我们希望 TS 能根据使用的事件类别的不同，对上下文进行匹配该事件类别的类型约束。

## 函数类型重载

利用 TS 的函数类型重载（[Function Overload](https://www.typescriptlang.org/docs/handbook/2/functions.html#function-overloads)），我们可以比较比较轻易的达成以上的诉求。函数类型重载是一种针对函数在不同方式被调用时采用不同的重载类型约束的类型描述方法。例如，以下是 `node.js` 中某个根据调用时不同形式的入参决定运行时行为的真实例子：

```ts
import net from 'net';

const server = net.createServer();

// directly pass a callback
server.listen(() => {
  console.log('done');
});

// pass a config object, and a callback
server.listen({
  port: 8081,
  host: 'localhost',
}, () => {
  console.log('done');
});

// pass in sequence port, host and callback
server.listen(8081, 'localhost', () => {
  console.log('done');
});
```

找到该方法的类型定义：

```ts
// @types/node/net.d.ts
listen(port?: number, hostname?: string, backlog?: number, listeningListener?: () => void): this;
listen(port?: number, hostname?: string, listeningListener?: () => void): this;
listen(port?: number, backlog?: number, listeningListener?: () => void): this;
listen(port?: number, listeningListener?: () => void): this;
listen(path: string, backlog?: number, listeningListener?: () => void): this;
listen(path: string, listeningListener?: () => void): this;
listen(options: ListenOptions, listeningListener?: () => void): this;
listen(handle: any, backlog?: number, listeningListener?: () => void): this;
listen(handle: any, listeningListener?: () => void): this;
```

这种针对一个方法声明多个不同函数描述的方式即为 TS 提供的函数类型重载。注意，由于以上文件（`.d.ts`）仅为类型文件，它只包含了 TS 函数重载种的重载签名（overload signature）部分；我们在写 TS 时，也需要在这些重载签名部分后面加上与之匹配的实现签名（implementation signature）部分，才能构成完备的具有类型重载的函数。

## 补全事件类型约束关系的 EventEmitter

将文章开头的 `EventEmitter` 子类按这种方式进行类型补全：

```ts
// an 'EventEmitter' subclass **with** explicit event type matching
class ServiceB extends EventEmitter {
    // overload signature
    public on(event: 'progress', callback: (percent: number) => void): this;
    public on(event: 'error', callback: (error: Error) => void): this;
    // implementation signature
    public on(event: string | symbol, callback: (...args: any[]) => void): this {
        return super.on(event, callback);
    }

    // overload signature
    public emit(event: 'progress', percent: number): boolean;
    public emit(event: 'error', error: Error): boolean;
    // implementation signature
    public emit(event: string | symbol, ...args: any[]): boolean {
        return super.emit(event, ...args);
    }
}

const b = new ServiceB();

// correct event & callback
b.on('progress', (percent) => {
    console.log('progress', percent * 100 + '%');
});
b.on('error', (error) => {
    console.log('error', error.message, error.stack);
});

// unmatched event & callback
// typescript gives error tips here
b.on('progress', (percent) => {
  console.log('progress', percent.value + '%'); // type error
});
b.on('error', (error) => {
  console.log('error', error.msg); // type error
});

// matched event & payload
b.emit('progress', 0.1);
b.emit('error', new Error('unavailable'));

// unmatched event & payload
// typescript gives error tips here
b.emit('progress', {x: {y: {z: 100}}}); // type error
b.emit('error', null, {msg: 'bad'});  // type error
```

可以看到，虽然有些累赘繁琐，但现在 TS 总算可以正确检查事件 `progress` `error` 的发布、订阅是否满足既定的类型约束了，我们的类型强迫症得以解决。利用这种方法，在很多依赖事件机制解耦的场合，我们都可以不必担心上下文类型丢失造成的困扰了。

## 备注

针对以上示例做几点说明：

1. `Service` 已经继承自 `EventEmitter` 了，原本是不需要将 `on` `emit` 的实现挂在子类的上的。但 TS 的函数类型重载要求重载签名（overload signature）后边必须接着函数的实现签名（implementation signature），只好再使用 `super.on` `super.emit` 调用父类的该方法以满足这个要求——可能会有更好的办法？...
2. `EventEmitter` 还具有 `once`、`addListener`、`off`、`removeListener` 等操作事件发布订阅相关行为的方法，理论上应该也用相同的方式为其补全类型，此处略过不表
3. 查看示例：[TS Playground](https://www.typescriptlang.org/play?#code/JYWwDg9gTgLgBAbzgUQG4FMB2NkmDGdKOAXzgDMoIQ4BydDbAZ1oG4Aodgei7gENMdNFhx58RWnCYBXAEYBjADZ8mTOACp1Ad3wALCNJia46AB5hFwefhON4MAJ5h0ceRExMYUPsGzslKmoAykSoVugAgiamhJgAJmrC2Lj4hMQI7HBZcDwAdPnsJJxuHvB8cAC8cJjoWnAhUGHykQAUAJQc3LxuUFDo8vAMInAAZK58ioqyfPIA1ux8ue4ttGBUAOZ9qrQANHAtzlDN2G2VAHyImdklTBCK6LmKEOsra89bLHuHx-DqcACMAAZAXAANR0ACktA6hRhi2W9F60F2+yIVCgpwqFwy2Vc7lu90ezxWaORe1JUFyIHQqj463Q5KRlM8M1mMJIMK6cGkmBAfBg8l06DitmGY3kEymrK5jmcTHkUGAYHg62AGDUmAgJiZcBgSqYCyWmFeGw+KIORB+mOxVxudweTxeq1NNM+cG+IlyqAm0hc4NoUPZcKNJKZ5op1suWTthMdofRKIpVKY6yDnR4cD5AqFIqG2FG7r4DiefDihvQeBgJverpRgNy-2DFfw8bJ1VqKCZKx5fG9wGUsnu0M5GZ5WcFwtF+bGYCLJbLGdlNIVSpVapp1S1FN1+vLlerzW2ewQpgAXIgHOeEAAvc9AwEkR9N-eIhN7TDSSbHkAp8+0aZxLQHKdFyAhCHYKQEBIUhyAEqgaNoejGGYFhWDYeb2E4LjjrovjrP4yjwQ0TToAAQtEsQJCgEGVmkUbZBmEAYFA85SMA6yYPy0h9FcWRgHIljyHAywYX+bybLWewSpM0xzOeFpHCI54fiAshEJGqAQMAcRtOeMC4UwHC4vxg5WMJxqiXQFIotJUpyaiTLnsgTIaVpOl6QZRkMbwoAWBWIj8sA7hsRxXE8cZAlmSJdjnp4iqYOscAAD5SA4ql3FJkqybM8n5LkfBQOsTDngIDgANoALqudpum6gZ9G4lkfQwNxggyIcIYYZlMmsjCuJFLxOS8ExRCsUw7GcS14XZCZgkmPulnOjWR7upaSnVNIqnqeesgQPaAheXxkVCc2VaLdZjLok5Lk7Xt9wHYNGa+fc1LYIFwXjaFU3oINs1madLSWXFeHJal6WKHseUFUVJWYOVVW3ftgg4o1TXoFNbXSB1ANdXAUOFUwfXZEUA03PAsiVO2dTEeEpHtOm3TQH0AxTvA4pZdKsghktEkrQpVrnA1eIePaRJOuJZpfGt+Z-PeYKQtCHDAewXMIhdDnopGKPRviotxq+bZJtStL0pd0C5Cycxppwo68vyE65nYBa2dlMpYfKirKnAqrqtq6I7mAahCjxqvGjzkv7B6JyCyjMYOsS4eSatinYF6Pp+grHRDbqWF+9AsIcKHrZQOGLkx7auuxgn6tGymWeLrnFIFzbvA4ZOGEFrOxYQKWKu5ADicrfWjaF-3L7qzUdTOei3acX2A5Dm0I68GO9s5qzndzj3C68EuHurt765qNueqB3Awc-VzA8S0nJ5XpeiC3gCwKPsB2dLnnUB9wPE+fhDiA-nWH+ACQEs7v0bkyIAA)
