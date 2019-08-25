---
layout: post
title:  understand cpp build
link:   understand-cpp-build
date:   2019-08-25 23:41:00 +0800
categories: cpp
---

## create executable

1. generate an execuatble(`a.exe` file in windows):

    ```bash
    # build executable
    g++ main.cpp
    ```

2. generate and set output executable file name to `hello.exe`:

    ```bash
    # build executable and set output name
    g++ main.cpp -o hello
    ```

3. The above commands do `compile` into `object file` and `link` with other object files and system libraries. Can also seperate into:

  ```bash
  # just compile, the output is defaultly `main.o`
  g++ -c main.cpp

  # if g++ target are object files, then it is `automatically linked`
  g++ main.o
  ```

## understand library

A library is a set of `pre-compiled` object files, which can be linked to our program via linker.

There are two type:

- static library. it's extension is `.a(archive)` in unix or `.lib(library)` in windows, and when linked, the machine code is directly copied into executable.
- shared library. it's extension is `.so(shared object)` in unix or `.dll(dynamic link library)` in windows. When used, when linked, only small table was created in executable, and system will try to load external machine code, which is so-called `dynamic linking`. It's just a sharable code library in operating system.

## headers and libraries

When build program:

- `compiler` will check `header files` to compile source codes. Each `#include` directive in codes will be checked. Very similar to `import` in `JavaScript` or some other.
- `linker` will check `libraries` to resolve references of object files or libraries. library path(`-Ldir`, `-L` followed with library path) and library name(`-lxxx`, `-l` followed with library name) are both needed.

## References

- <https://www3.ntu.edu.sg/home/ehchua/programming/cpp/gcc_make.html>
- <https://www.learncpp.com/cpp-tutorial/introduction-to-the-compiler-linker-and-libraries/>
