---
layout: post
title:  使用 jest mock 模块
link:   use-jest-to-mock-module
date:   2019-12-10 23:27:00 +0800
categories: test
---

在编写单元测试的过程中，总是会需要营造各种各样的测试条件和场景。一般的，我们可以通过准备 mock 数据的形式去进行单元测试，但很多时候这些 mock 数据需要传入待测试的方法然后层层处理，使得制造恰当的 mock 数据或验证这些数据的处理流程是否正确的过程都有不小的困难。但有时也可以换个思路，将数据处理流程中和测试目标不相关的部分替换掉，达到快速验证的目的。

以下将以 `Jest` 为例罗列一些使用 `mock` 的方式或方法。

## mock 模块

```js
const mockFn = jest.fn();
jest.mock('@/utils/helper', () => ({
  formatData: mockFn,
}));
```

## mock 模块中的某个方法

```js
const mockFn = jest.fn();
jest.mock('@/utils/helper', () => ({
  ...jest.requireActual('@/utils/helper'),
  formatData: mockFn,
}));
```

## 重置模块或 mock

```js
describe('some test', () => {
  beforeEach(() => {
    mockFn.mockReset();
    jest.resetModules();
  });
});
```

## 参考

- <https://jestjs.io/docs/en/getting-started>
