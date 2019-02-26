---
layout: post
title:  面向类型编程：Typescript 中的高级类型
link: advanced-types-in-typescript
date:   2018-12-25 16:24:00 +0800
categories: typescript
---

> "动态一时爽，重构火葬场"
>
> "其实一旦接受了这种设定，还是很带感的"

在越来越多的项目中开始使用 `typescript` 之后，越来越觉得预定义类型及类型推断的重要性及其带来的好处了。是的，使用类型非常简单，一般来说只需要在声明变量时声明其可能的数据类型或结构，后续关于它的一切都交给 `typescript` 的静态类型检查及推断，在编码阶段就能避免大量潜在的错误。

# 基本类型

一般来说，我们常用到以下基本数据类型：`any` `boolean` `number` `string` `undefined` `null` `object` `Array` `Function` 等。为了更具体的描述对象(object)的数据结构，也常使用接口。接口使用关键字 `interface` ，通过它定义一种对象数据结构：

```typescript
interface IPet {
  name: string;
}
```

接口能够通过关键字 `extends` 对数据结构做继承拓展，甚至能够同时拓展自多个其他类型(多重继承)：

```typescript
interface IAnimal {
  favorites?: string[];
}
//  ICat 类型继承自 IPet 及 IAnimal，因此也拥有字符串类型的 name 属性, 以及 字符串数组类型的 favorites 属性
interface ICat extends IPet, IAnimal {
  color: string;
}
```

上例中，`IAnimal` 类型的 `favorites` 属性被标记为可选的(?)，这意味着在进行代码检查时，该属性可能存在也可能不存在(undefined)。符号 `?` 是关于属性描述的一种修饰符。

# 高级类型

有时某个类型只是其他类型的别名，可以使用 `type` 关键字来定义类型的别名，方便后续使用：

```typescript
type NumberArray = Array<number>;
const numberList: NumberArray = [1, 3, 10, 20];

type CatArray = Array<ICat>;
const catList: CatArray = [
  // ...
];
```

在上面的例子里，数组类型 `Array` 实际上接受另外一个类型(例如 `number` 或者是我们自定义的 `ICat` 类型作为参数，然后返回一个全部都由该类型组成的数组。这使得 `Array` 具有了抽象任何其他类型作为数组的能力。这个“类型参数“ 在 typescript 中称为**泛型**(generic)——一种泛指的类型变量。

既然拥有了“类型变量”，倘若结合一定的逻辑运算，是否能创造更多的可能性？答案是肯定的，`typescript` 通过一些方式提供了类型推断的种种可能，使其对实际代码的描述能力大大提高。以下我们通过一些例子简要的了解一下这种“面向类型的编程”。

## 并集 union

[并集](https://en.wikipedia.org/wiki/Union_(set_theory)) 是若干个集合所包含的全部元素组成的集合。例如，集合 `a = [string, number, boolean]` 与集合 `b = [string, boolean, Function]` 的并集是集合 `[string, number, boolean, Function]`, 并集中已包含集合 `a` 与 `b` 的全部成员。
换句话说，并集中的某个元素，既可能是 `a` 的成员，也可能是 `b` 的成员。

在 `typescript` 中，使用**或运算符** `|` 代表这种关系，例如：

```typescript
//  value 既可以是 number，也可以是 string, 它的类型是 number 与 string 的并集
let value: number | string = 100;
value = '100';

interface IApple {
  name: string;
  color: string;
}
interface IBanana {
  name: string;
  length: number;
}
//  fruit 的类型是多个(复杂)类型的并集
let fruit: IApple | IBanana | undefined;
```

## 交集 intersection

[交集](https://en.wikipedia.org/wiki/Intersection_(set_theory)) 是若干个集合都共有的全部元素组成的集合。例如，集合 `a = [string, number, boolean]` 与集合 `b = [string, boolean, Function]` 的交集是集合 `[string, boolean]`, 交集中的每个元素既是集合 `a` 的成员，也是集合 `b` 的成员。

在 `typescript` 中，使用**与运算符** `&` 代表这种关系，例如:

```typescript
//  IAppleBanana 具有全部的三种属性 name, color, length，因此它既可以认为是 IApple，也可以认为是 IBanana, 是 IApple 与 IBanana 的交集。
type IAppleBanana = IApple & IBanana;
const ab: IAppleBanana = {
  name: 'ab',
  color: 'red',
  length: 10,
};
```

注意，对于接口，`{ name, color, length }` 是 `{ name, color }` 的子集，因此接口的交集是接口包含的全部键的并集组成的类型。

## 类型索引

`typescript` 提供了关键字 `keyof` 以获得一种类型(通常是接口) 下所有的键构成的集合。

例如:

```typescript
//  声明接口，满足该接口声明的对象必然具有 x, y 属性
interface IPoint {
  x: number;
  y: number;
  type: string;
}
//  使用关键字 keyof 获得 IPoint 的全部 key 组成的合集
//  相当于 type IKeyOfPoint = 'x' | 'y' | 'type';
type IKeyOfPoint = keyof IPoint;

//  既然有了“键”, 就可以通过 [] 运算符获取“值”：
//  相当于 IValueOfPoint = string | number;
type IValueOfPoint = IPoint[IKeyOfPoint];

//  从 IPoint 里取特定的键值
function getValueFromPoint(obj: IPoint, key: IKeyOfPoint): IValueOfPoint {
  return obj[key];
}
```

上面定义的方法 `getValueFromPoint` 声明了只能针对 `IPoint` 对象使用。但配合 `泛型`，可以实现一些更通用的类型声明：

```typescript
//  只使用一个泛型 T
function getValues<T>(obj: T, keys: Array<keyof T>) {
  return keys.map(key => obj[key]);
}
//  使用两个泛型 T, K，其中 K 必须要从类型 "keyof T" 继承而来, 并且输出类型与原类型一一对应
function plunk<T, K extends keyof T>(obj: T, keys: K[]): T[K][] {
  return keys.map(key => obj[key]);
}

const apple: IApple = {
  name: 'apple',
  color: 'red',
};
const appleValues = pluck(apple, ['name', 'color']);
```

## 类型映射 Mapped Types

`typescript` 提供了关键字 `in` 用来约束类型是否属于某个类型集合。配合类型查询，可以创造出一些用于产生衍生类型的工具类型：

```typescript
// 将泛型 T 的所有键都标记为非必须(?)
type Partial<T> = {
  [P in keyof T]?: T[P];
}
// Partial<IPoint> 是 IPoint 的键值对非必需版本， 相当于 { x?: number; y?: number; type?: string }
const p0: Partial<IPoint> = {
  x: 200,
}

// 将泛型 T 的所有键都去除掉非必须(-?)
type Required<T> = {
  [P in keyof T]-?: T[P];
};
//  Required<Partial<IPoint>> 是 Partial<IPoint> 的键值对必需版本，相当于又回到了 IPoint
const p1: Required<Partial<IPoint>> = {
  x: 100,
  y: 100,
  type: 'rect',
}

//  从泛型 T 的所包含的键值类型中选择若干，并构成一个新的类型
type Pick<T, K extends keyof T> = {
  [P in K]: T[P];
}

//  Pick<IPoint, 'x' | 'y'> 从 IPoint 中选择 'x' 和 'y' 组成新的对象类型, 相当于 { x: number, y: number }
const p2: Pick<IPoint, 'x' | 'y'> = {
  x: 200,
  y: 200,
}
```

于是，我们拿到了以下辅助类型：`Partial<T>`, `Required<T>`, `Pick<T, K>`。

## 条件类型

`typescript` 拥有一定程度的类型运算逻辑。类似于**三目条件运算符** `condition ? a : b`, 可以对某类型（泛型）进行类型条件运算推断：

```typescript
//  类型 FruitType<T> 实际类型由泛型推断而来
//  如果 T 满足 number 类型的约束，则返回 IApple 类型；否则返回 IBanana 类型
type FruitType<T> = T extends number ? IApple : IBanana;

//  f 被推断为 IApple 对象
const f:FruitType<123> = {
  name: 'apple',
  color: 'red',
}
```

把这种逻辑结合泛型应用在并集类型上，可以衍生出一系列颇为实用的工具类型：

```typescript
//  定义两个 Union 类型
type ICollectionA = 100 | 'abc' | null;
type ICollectionB = undefined | null;

//  从泛型 T 中过滤选择出能够满足 泛型 U 约束的类型
//  注意这里和直观的认知不同，并不是真的返回完整的 T 类型，而是返回 T 类型中满足 U 约束的类型
type Filter<T, U> = T extends U ? T : never;

//  从 100 | 'abc' | null 中过滤出满足 undefined | null 的类型，即 null
type INull = Filter<ICollectionA, ICollectionB>;

//  与 Filter 刚好相反，从泛型 T 中剔除能够满足泛型 U 约束的类型
type Exclude<T, U> = T extends U ? never : T;

//  从 100 | 'abc' | null 中排除掉满足 undefined | null 的类型，即 100 | 'abc
type IDefined = Exclude<ICollectionA, ICollectionB>;
```

再进一步，利用前面得到的 `Pick<T, K>` 和关键字 `keyof`，可以声明以下类型：

```typescript
//  与 Pick<T, K> 正好相反，从 T 中去除 K 包含的类型
//  先把 T 对象中的所有键类型罗列出来，并从中移除满足 K 约束的，再利用 Pick 将剩余的键类型保留为新的对象类型
type Omit<T, K> = Pick<T, Exclude<keyof T, K>>;

//  从 IPoint 中剥离键满足 'type' 的类型
const IXY: Omit<IPoint, 'type'> = {
  x: 100,
  y: 100,
}
```

通过以上的实例可以发现，`typescript` 通过有限的类型关键字或运算符 `interface` `type` `extends` `|` `&` `keyof` 以及属性修饰符 `?` `-` `!` 等，结合 "类型的变量——泛型"，衍生出了一系列非常实用的工具类型，可谓是 `typescript` 里的 `lodash` 方法集了！现简单整理如下：

|工具类型|说明|已内置|
|---|---|---|
|`Partial<T>`|将泛型 T 的所有键都标记为非必须(?)|✅|
|`Required<T>`|将泛型 T 的所有键都去除掉非必须(-?)|✅|
|`Pick<T, K>`|从泛型 T 的所包含的键值类型中选择若干，并构成一个新的类型|✅|
|`Omit<T, K>`|从 T 中去除 K 包含的类型|❌|
|`Filter<T, U>`|从泛型 T 中过滤选择出能够满足 泛型 U 约束的类型|❌|
|`Exclude<T, U>`|从泛型 T 中剔除能够满足泛型 U 约束的类型|✅|

# 高级类型使用

以下通过两个实际编码场景来简单应用一下以上所学习的高级类型。

## 可选配置项

某模块通过参数 options 提供配置选项供使用者配置时，这些配置选项通常都是可选的；然而在模块内部收到配置项时，也常使用 "默认配置项" 与使用者的配置项合并补全成完整的配置项。这样一来，对于外部使用者来说，options 的每一个属性都是可选的，而对于内部使用者来说，options 的每一个属性都已被补全，因此能直接使用。

一般的，可以定义类型 `IOptions` 并通过属性修饰符 `?` 表明属性为可选；再在使用时，通过修饰符 `!` 标注该属性一定存在——这种做法虽可行，但是每次使用时都需要加 `!` 显得比较繁琐。这时可以使用上面提到的 `Required` 并衍生出类型 `Required<IOptions>` 来描述这种差异。例如：

```typescript
//  对外暴露的类型，指示用户配置项的每一个属性都是可选的
export interface IOptions {
  uid?: number;
  name?: string;
}

//  对外暴露的方法
export function useModule(options?: IOptions) {
  const opt: Required<IOptions> = {
    uid: 0,
    name: 'none',
    ...options,
  }
  // 后续使用 opt 时，都可以认为每个属性都存在
  // ...
}
```

## React 高阶组件 (HOC)

高阶组件(Higher Order Component) 在 React 开发中是一种常用的范式。通过创建一个能够在运行时动态创建新的组件(类或方法)的方法，可以实现对原组件无侵入的注入(inject)属性或剔除(expel)属性的目的。

下面对组件 `Box` 进行 HOC 加工声明以阐述这种方法。

```tsx
import * as React from 'react';

//  原组件的类型声明及其实现
export interface IBoxProps {
  name: string;
  size: number;
}
export default class Box extends React.Component<IBoxProps> {
  public render() {
    const { name, size } = this.props;
    return (
      <div>{name} : {size}</div>
    );
  }
}
```

### 属性注入(inject)

属性注入的本质是动态创建一个新的组件(类或方法)，它除了接收原组件的全部属性并且把它们直接传递或间接加工传递给原组件之外，还根据需要另外接收一些类型的参数。假如原组件参数类型为 `IProps`, 要额外添加的属性为 `IInjectedProps`, 那么动态创建的组件的类型就应该是 `IProps & IInjectedProps`, 并且在该组件逻辑内，仅传递正确的 `IProps` 给原组件以确保类型传递正确。

以下是属性注入的一份 `typescript` 实现:

```tsx
import Box from './Box';

//  想要注入的属性类型声明
interface IInjectProp {
  visible: boolean;
}

//  注入 IInjectProp 属性并动态创建新组件的方法
function injectComp<P extends object>(Comp: React.ComponentClass<P>) {
  type IInjectedProp = P & IInjectProp;
  return class InjectedComp extends React.Component<IInjectedProp> {
    public render() {
      const { visible, ...rest } = this.props;
      return (
        visible ? (
          <Comp {...rest}/>
        ) : (
          <div>nothing here...</div>
        )
      )
    }
  }
}

//  经注入属性后的高阶组件
export const InjectedBox = injectComp(Box);
```

### 属性剔除(expel)

与属性注入正好相反，属性剔除是动态创建一个新的组件(类或方法)并提供部分预设的属性，这样一来，生成的组件只接收原组件属性中的一部分，其他部分的属性对于使用者来说相当于是被剔除了——从另一个角度上看，也可以认为是对原组件预先注入了部分定义好的属性。另外，鉴于组件本质上是方法调用及参数列表，因此也可以把这种方式看作组件的柯里化(currying)。

以下是属性剔除的一份 `typescript` 实现:

```tsx
//  原组件
import Box from './Box';

//  从 T 中去除 K 包含的类型
export type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;

interface IExpelProp {
  size: number;
}

//  剔除 IExpelProp 属性并动态创建新组件的方法
function expelComp<
  P extends IExpelProp,
  K extends Partial<P>>(Comp: React.ComponentClass<P>, expel: K) {
  type IExpelledProp = Omit<P, keyof Partial<P>>;
  return class ExpelledComp extends React.Component<IExpelledProp> {
    public render() {
      return (
        <Comp {...this.props} {...expel}/>
      );
    }
  }
}

//  经剔除属性后的高阶组件
export const ExpelledBox = expelComp(Box, { size: 100 });
```

类似的，React v16.3+ 的 `context`, `react-redux` 或者 `mobx` 的 store 属性注入等，也可以用类似的方式来描述。一般来说这些第三方类库已在其配套的类型定义文件中声明了注入方法的原型，不需要自己再手动编写。

注：在最近的几个版本的 `typescript` 中, 对 react 组件声明注入使用的工具类型可能存在 bug, 导致 ts 编译报错 [issue#28748](https://github.com/Microsoft/TypeScript/issues/28748)；本文仅阐述高级类型的使用方式，不确保编译正确。

# 总结

`Typescript` 的高级类型为复杂的类型表达和推断提供了更多便利和可能。对于强迫症患者来说，为了能自然的使用类型，增加了不少学习和维护成本，堪称为“面向类型编程”也不为过。但它并非完美无瑕无懈可击，在复杂性增加后，也存在各种BUG(尤其是配合 React 生态使用时)，非常影响开发体验——也许适当的灵活使用 `as` 关键字绕过复杂的类型推断反而更实际。

## 参考链接：

- <https://www.typescriptlang.org/docs/handbook/advanced-types.html>
- <https://github.com/basarat/typescript-book/>
- <https://github.com/pelotom/type-zoo>
- <https://medium.com/@thehappybug/using-react-context-in-a-typescript-app-c4ef7504c858>
- <https://github.com/piotrwitek/react-redux-typescript-guide>
