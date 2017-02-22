---
layout: post
title:  Javascript 原型、类、继承
date:   2017-02-22 11:19:00 +0800
categories: javascript
---

在 Javascript 里实现类、继承这种面向对象的特性，离不开对象的原型。最早接触 js 的时候，不求甚解，一般是参照网上抄来的方法这样实现的：

```javascript
var Animal = function (name) {
  this.name = name || 'NO_NAME'
}

Animal.prototype.hello = function () {
  console.log('Hello, this is ' + this.name)
}

var Cat = function (name, age) {
  this.name = name
  this.age = age
}

Cat.prototype = new Animal()

var kitty = new Cat('Kitty', 1) 
kitty.hello()
```

js 的对象可以理解成一个键值对应关系的集合。对象的`原型(prototype)` 是一个特殊的键值，通过它可以帮助实现一些面向对象的特性。对于一个普通的对象定义，例如 `var obj = {}`, 它也有原型, 只不过值是 `undefined`。

可以通过 `obj.__proto__` 访问或者原型对象，但是这个访问方式并不是规范内的，仅仅是为了兼容性才保留支持。也可以通过 `Object.getPrototypeOf()` 访问以及 `Object.setPrototypeOf()` 设置原型对象，但应该也是要尽量避免的。
 
对于一个 js 对象，当通过 `.` 或者 `[]` 尝试访问它的方法或者属性的时候，会先检查这个属性或者方法是否挂载在自身上；如果没有，就向上查找它的原型对象,依次类推。
如果到了原形链的最末端仍然没有此属性或方法，才会返回 `undefined` 表示没有找到。

---

通过以上的对象访问过程，可以推测出以下几点：

- 访问某对象的一个不存在的属性，或者是从原型链上继承来的属性，理论上说应该是相对而言比较慢的，因为这种情况会向上搜索原型链上查找。但是奇怪的是经过了一些测试，发现区别不明显，具体原因还有待研究。

  ```javascript
  var benchmark = require('benchmark')
  var suite = new benchmark.Suite()
  function Parent() { this.delta = 10; };

  function ChildA(){}
  ChildA.prototype = new Parent()
  function ChildB(){}
  ChildB.prototype = new ChildA()
  function ChildC(){}
  ChildC.prototype = new ChildB()
  function ChildD(){}
  ChildD.prototype = new ChildC()
  function ChildE(){}
  ChildE.prototype = new ChildD()

  function nestedFn() {
    var child = new ChildE()
    var counter = 0;
    for(var i = 0; i < 1000; i++) {
      for(var j = 0; j < 1000; j++) {
        for(var k = 0; k < 1000; k++) {
          counter += child.delta;
        }
      }
    }
  }

  function cachedFn () {
    var child = new ChildE()
    var counter = 0
    var delta = child.delta
    for(var i = 0; i < 1000; i++) {
      for(var j = 0; j < 1000; j++) {
        for(var k = 0; k < 1000; k++) {
          counter += delta;
        }
      }
    }
  }

  var tm = {}
  function measure(id, action) {
    var now = Date.now()
    action()
    tm[id] = Date.now() - now
    console.log(id, tm[id])
  }

  measure('nested-visit', nestedFn)
  measure('cached-visit', cachedFn)

  suite.add('nested-visit', nestedFn)
    .add('cached-visit', cachedFn)
    .on('complete', function () {
      console.log('Fastest is ' + this.filter('fastest').map('name'))
    })
    .on('cycle', function (event) {
      console.log(String(event.target))
    })
    .run({async: true})
  ```
- 对象的原型也是一个对象，可以拥有属性和方法，可以在运行时访问或修改。比如扩展 Array.forEach 的实现，通常直接挂载在 Array 对象的原型上：

  ```javascript
  Array.prototype.forEach = function(cb) {
    for (var i = 0; i < this.length; i ++) {
      cb(this[i], i)
    }
  }
  ```

- 把构造函数作为普通函数调用，通过返回新建对象，可以避免使用关键字 `new`:

  ```javascript
  var Animal = function (name) {
    // function prototype is Object
    var a = Object.create(Animal.prototype)
    a.name = name
    return a
  }

  var animal = Animal()
  ```