---
layout: post
title:  using-docker
date:   2018-02-22 15:16:00 +0800
categories: linux
---

### Image & Container

**镜像(Image)** 与 **容器(Container)** 在 docker 里是不同的两个概念。镜像相当于是一份代码仓库，而容器是某个代码库运行的实例环境。 比如，docker 命令中的 `rm` 和 `rmi` 后者的删除主体是镜像而不是容器。

### `docker ps`

使用 `docker ps` 查看当前**正在运行**的镜像列表。

使用命令 `docker rmi hello-world` 尝试删除本地镜像 `hello-world` 时报错，提示：

```bash
Error response from daemon: conflict: unable to remove repository reference "hello-world" (must force) - container 442058f0c1af is using its referenced image 725dcfab7d63
```

原因是有曾经运行过的容器引用到了该镜像，如果删掉了该镜像就无法运行了。可以通过 `ps` 命令附加参数 `-a` 查看所有曾经运行过的容器：

```bash
docker ps -a
```

可以通过 `rmi` 命令附加参数 `-f` 强制删除该镜像：

```bash
docker rmi -i hello-world
```


### [`docker run`](https://docs.docker.com/engine/reference/commandline/run/#options)

使用 `docker run` 运行镜像并通过 `--name=<name>` 指定运行名时，可能会遇到名称冲突：

```bash
docker: Error response from daemon: Conflict. The container name "/web" is already in use by container "6238443388c7b4d9e03df56521610beab651a46b860af5a42d602073bc2c9ec2". You have to remove (or rename) that container to be able to reuse that name.
```

这是因为容器名被其他正在运行的容器占用了。可以通过上面的 `docker ps -a` 查看所有运行的容器信息来确定是否有冲突。如果的确有冲突的容器，可以考虑通过命令 `docker stop <name>` 停止容器服务或直接删除 `docker rm <name>`.

为了避免容器名称冲突，可以在运行镜像时使用参数 `--rm` 使容器退出后自动删除容器：

```bash
docker run --name=<name> --rm <image>
```

使用参数 `-d` 使容器运行于分离模式(detach mode)下，否则会占用当前命令行的输出。可以用参数 `-it` 开启交互式(interactive)虚拟终端以交互(pseudo-TTY)；在这种模式下，如果程序没有处理进程的中断信号(SIGINT, SIGTERM), 会无法在当前终端退出([参考1](https://github.com/moby/moby/issues/2838), [参考2](https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#cmd))。为避免这种情况，可以使用参数 `--init` 确保容器可以正确传递进程信号给执行程序([参考3](https://github.com/krallin/tini))：

```bash
docker run --name=<name> --rm -it --init <image>
```

使用参数 `-v` 使当前系统目录挂载到容器目录下，这样对容器内外的目录内的任何文件变更都会互相同步：

```bash
docker run -d --rm -v ./data:/data <image>
```

可以在镜像名后添加命令，用来执行容器环境中环境变量或者路径里找到的可执行程序，例如, 以下命令执行后开启了容器内的终端，当希望进入容器内的终端查看相关数据的时候很有用：

```
docker run -it --rm <image> bash
```

### 清理不使用的 images, network, containers 等

在使用 `docker build` 的过程中总是会多出一些没有 tag (`none`) 的镜像。可以通过

```bash
docker images prune
```

来清除不需要的这些镜像。另外可以使用 `docker system prune` 来清除各种docker相关的不使用的资源。

### node with docker

#### 选择合适的 node 镜像版本作为 base image([参考](https://derickbailey.com/2017/03/09/selecting-a-node-js-image-for-docker/))

推荐使用 alpine 版本

#### 在容器内通过 npm 安装来自私有源的依赖([参考](https://docs.npmjs.com/private-modules/docker-and-private-modules))

如果项目中有需要安装来自私有源(cnpm)的依赖，`docker build` 内运行 `npm install` 会产生安装失败（如果有 package-lock.json 甚至会报 node_modules 目录下文件没找到这种毫不相干的奇怪错误）。此时有两种办法：

1. 在 `Dockerfile` 里额外写一些命令，更改容器内的 `npm` 设置，例如：

  ```Dockerfile
  RUN npm install -g nrm
  RUN nrm add https://my-cnpm-registry.com mycnpm
  RUN nrm use mycnpm
  RUN npm install
  ```

2. 更简单一点，可以在当前项目下使用文件 `.npmrc` 单独配置 npm:

  ```.npmrc
  registry=https://registry.npmjs.org
  @myspace:registry=https://my-cnpm-registry.com
  ```

然后在容器内执行 `npm install` 之前把此文件拷贝到容器工作目录内：

  ```Dockerfile
  COPY package*.json /app/
  COPY .npmrc /app/

  RUN npm install
  ```

#### 容器内数据库资源持久化存储(mongo, redis)

#### 减少镜像文件体积

### Practice: 包含私有源依赖的纯前端项目

### Practice: 包含私有源依赖的node项目