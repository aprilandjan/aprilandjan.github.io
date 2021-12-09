---
layout: post
title: fix macos image not found in node native binding
link: fix-macos-image-not-found-in-node-native-binding
date: 2021-12-08 21:08:00 +0800
categories: nodejs
---

## Problem

The workspace primary folder structure are as followed:

```bash
/my/native-binding/
├── lib
│   └── mac
│       └── binding.node
└── sdk
    └── sdk.framework
```

The problem is: when try to directly require this `binding.node` and dynamically load the `sdk.framework` in the `sdk` folder, the terminal always throws following error:

```bash
internal/modules/cjs/loader.js:1144
  return process.dlopen(module, path.toNamespacedPath(filename));

Error: dlopen(/my/native-binding/lib/mac/binding.node, 1): Library not loaded: @rpath/sdk.framework/Versions/A/sdk
  Referenced from: /my/native-binding/lib/mac/binding.node
  Reason: image not found
    at Object.Module._extensions..node (internal/modules/cjs/loader.js:1144:18)
    at Module.load (internal/modules/cjs/loader.js:950:32)
    at Function.Module._load (internal/modules/cjs/loader.js:790:14)
    at Module.require (internal/modules/cjs/loader.js:974:19)
    at require (internal/modules/cjs/helpers.js:92:18)
    ...
```

## otool

Check an installed electron app:

```bash
$ otool -l /Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron
/Applications/Visual Studio Code.app/Contents/MacOS/Electron:
Load command 24
          cmd LC_RPATH
      cmdsize 48
         path @executable_path/../Frameworks (offset 12)
Load command 25
      cmd LC_CODE_SIGNATURE
  cmdsize 16
  dataoff 349216
 datasize 38608
```

## dyld

## install_name_tool

```bash
$ install_name_tool -add_rpath /my/native-binding/sdk/ /my/native-binding/lib/mac/binding.node
```

## spctl

```bash
$ sudo spctl --master-disable
```

## xattr

```bash
$ sudo xattr -r -d com.apple.quarantine ./lib/sdk.framework
```

This will remove the quarantine flag from the framework, which is preventing the framework from being run.

## references

- <https://stackoverflow.com/questions/19776571/error-dlopen-library-not-loaded-reason-image-not-found>
- <https://medium.com/@donblas/fun-with-rpath-otool-and-install-name-tool-e3e41ae86172>
- <https://blog.krzyzanowskim.com/2018/12/05/rpath-what/>
- <https://github.com/SAP/node-rfc/issues/140>
- <https://community.adobe.com/t5/air-discussions/adobe-air-framework-is-damaged-and-can-t-be-opened/td-p/10793982>
