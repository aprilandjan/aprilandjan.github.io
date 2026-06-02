---
layout: post
title:  map-functions-to-their-return-types-in-typescript
link: Map functions to their return types in typescript
date:   2020-08-23 22:27:00 +0800
categories: typescript
---

When writing redux actions in `typescript`, it's common to obtain all action creators into one object. For example:

```typescript
function createActionA () {
  return {
    type: 'a',
    payload: 1,
  }
}

function createActionB () {
  return {
    type: 'b',
    payload: 'data'
  }
}

const actionCreators = {
  createActionA,
  createActionB,
}
```

Also we might need the union of all these actions. Of cause we can define separately and use them:

```typescript
interface ActionA {
    type: 'a',
    payload: number;
};

interface ActionB {
    type: 'b',
    payload: string;
}

type Actions = ActionA | Action B;
```

But that is always annoying to write. We can use the utility type `ReturnType` to directly get the return type of one function, for example:

```typescript
type ActionA = ReturnType<typeof createActionA>;
type ActionB = ReturnType<typeof createActionB>;
type Action = ActionA | ActionB;
```

This is much better, but still not enough, since if we add more action creators, we had to maintain that manually. If we have the `actionCreators` which hold all the creator functions, there must be some tricks to get the union of all the actions.

Let's have a try:

```typescript
function createActionA () {
  return {
    type: 'a',
    payload: 1,
  }
}

function createActionB () {
  return {
    type: 'b',
    payload: 'data'
  }
}

const actionCreators = {
  createActionA,
  createActionB,
}

//  the type representing `actionCreators` object
type C = typeof actionCreators;

//  the string union of key-of `actionCreators` object
//  'createActionA' | 'createActionB'
type D = keyof C;
//  the union of the typeof action-creator functions
//  () => { type: string, payload: number} | () => { type: string, payload: number }
type E = C[D];
//  although the above `E` is an union
//  the return type of it is automatically mapped as the union of these functions
//  { type: string, payload: number} | { type: string, payload: number }
type F = ReturnType<E>;

//  combine all above
type Actions = ReturnType<(typeof actionCreators)[keyof typeof actionCreators]>;

//  make it more abstract
type MappedReturnType<T extends { [key: string]: any}> = ReturnType<T[keyof T]>;
//  finally we got `Actions1`, it is identical with `Actions`
type Actions1 = MappedReturnType<typeof actionCreators>;
```

From all the above codes, we can know that:

1. The utility type `ReturnType` can automatically works on `Union` and return `Union` of individual return types. That is beyond what we expected!
2. Combined with generic type params, we created another utility type `MappedReturnType<T>`, which might be useful in other cases.

## References

- <https://www.typescriptlang.org/docs/handbook/utility-types.html>