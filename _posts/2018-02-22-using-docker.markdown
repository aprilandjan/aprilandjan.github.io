---
layout: post
title:  using-docker
date:   2018-02-22 15:16:00 +0800
categories: linux
---

## Image & Container

**镜像(Image)** 与 **容器(Container)** 在 docker 里是不同的两个概念。镜像相当于是一份代码仓库，而容器是某个代码库运行的实例环境。 比如，docker 命令中的 `rm` 和 `rmi` 后者的删除主体是镜像而不是容器。

## `docker ps`

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


## [`docker run`](https://docs.docker.com/engine/reference/commandline/run/#options)

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

来清除不需要的这些镜像; 相似的，也有 `docker container prune` 来清除非运行状态的容器；最后，可以使用 `docker system prune` 来清除各种docker相关的不使用的资源(image, container, network等)。

## node with docker

### 选择合适的 node 镜像版本作为 base image([参考](https://derickbailey.com/2017/03/09/selecting-a-node-js-image-for-docker/))

推荐使用 alpine 版本

### 在容器内通过 npm 安装来自私有源的依赖([参考](https://docs.npmjs.com/private-modules/docker-and-private-modules))

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

### 容器内数据库资源持久化存储(mongo, redis)

### 减少镜像文件体积

## Practice: Pure frontend webpack+MVVM framework project

### 开发环境

虽然从实用角度上看没有必要把这种项目的开发环境放在 docker 里作为镜像运行，但是出于熟悉 docker 的目的，尝试了一下这个过程。有以下几个需要注意的点：

1. Base Image 可能需要完全版本的 node 镜像(carbon), 否则一些需要编译的依赖可能会因为镜像环境中没有相关工具类库而导致安装失败，例如 `node-sass`;

2. 配置 `.npmrc` 文件以确保在容器内可以正确安装依赖；

3. 为了实现开发过程中 webpack 热更新，需要在运行镜像时设置挂载点(volume), 使镜像内 webpack 监听文件变更的目录与本地可操作目录同步：

  ```bash
  docker run -it \
    --rm \ 
    -p 3000:3000 \
    --name=web \
    -v $PWD/src:/app/src
    docker-vue
  ```

注意 `-v` 只接受绝对路径，所以用变量 `$PWD` 指代当前的本地工作目录。也可以把这行命令写成 `docker-compose.yaml` 执行：

```docker-compose.yaml
version: "3"
services:
  web:
    build:
        context: .
        dockerfile: Dockerfile
    image: docker-vue
    ports:
      - 3000:3000
    volumes:
      - $PWD/src:/app/src
```

然后直接运行 `docker-compose up` 即可。

### 生产环境

生产环境比较简单，build 完生成静态文件之后即可把不必要的文件删除，减少镜像体积（[参考](https://medium.com/dirtyjs/how-to-deploy-vue-js-app-in-one-line-with-docker-digital-ocean-2338f03d406a)）

## Practice: Koa + Nuxt + Mongo project

这个项目需要经由 nuxt 编译生成静态文件资源，再通过 Koa 提供服务，并使用 Mongo 作为数据存储。如果不使用容器，部署的时候需要在服务器上单独安装 mongo, node 并拉取源代码编译运行。使用容器可以把整个项目需要的一切打包在一起。

首先是把 node 端的资源容器化， 使用 [multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/) 的方式 build 一份最小的镜像：

```Dockerfile
# ----- base node -----
FROM node:carbon AS base

WORKDIR /app/web

COPY package*.json .

# ----- build with carbon -----
FROM base AS build

# install only production dependencies
RUN npm install --only-production

# copy production dependencies aside
RUN cp -R node_modules prod_node_modules

COPY . .

# install all dependencies
RUN npm install

# build nuxt static files, get the .nuxt static folder
RUN npm run build

# ----- release with alpine -----
FROM node:8.9.4-alpine AS release 

ENV PORT=3000

EXPOSE $PORT

ENV NODE_ENV=production

WORKDIR /app/web

COPY --from=build /app/web/package.json .
COPY --from=build /app/web/prod_node_modules node_modules
COPY --from=build /app/web/.nuxt .nuxt

# COPY server resources
COPY server server
COPY static static
COPY config.js .
COPY nuxt.config.js .

RUN ls -a

CMD npm run start
```

上面的示例中，首先在 `base` 镜像里安装生产环境的依赖并另存为其他目录，再下载完全部依赖，之后进行编译产出静态文件；之后再从 `release` 镜像里拷贝服务运行需要的依赖和文件，作为镜像入口。这样以来，提供 web 服务的镜像就完成了。

另外还需添加 `network` 以供镜像之间互联、开启 mongo 镜像。注意 mongo 镜像通过参数 `--hostname` 指定了一个名称 `mymongo` 使得其他容器可以通过此名称访问到它：

```bash
docker network create blognet
docker run -d --name=mymongo --network=blognet --hostname=mymongo mongo
docker run --rm -p 3000:3000 --network=blognet --name=myblog -it myblog
```

使用 `docker-compose` 把以上过程合并为文件如下：

```docker-compose.yaml
version: "3"
services:
  mongo:
    image: mongo:latest
    container_name: mymongo
    networks:
      - blognet
  web:
    build:
      context: .
      dockerfile: Dockerfile
    image: myblog
    depends_on:
      - mongo
    networks:
      - blognet
    ports:
      - 3000:3000
networks:
  blognet:
    driver: bridge
```

这样即可通过一行命令 `docker-compose up` 来部署整个服务了。有时改动 `docker-compose.yaml` 重启会仍然使用改动前的容器配置，可能需要手动执行 `docker rm` 确保修改生效。

### 多环境配置

开发环境下需要使用 docker-compose 启动所需要的全部服务，需要使用 volume 映射路径, 需要跑开发环境的命令；而发布环境里，最终部署时也需要 docker-compose 把各个服务串联起来。这两个环境所需要的 nodejs 的镜像可能差距很大：开发环境下得有热更新，得共享目录，得安装 devDependency，得编译源代码等等，所以，感觉一份 Dockerfile 是无法仅仅通过几个环境变量的差异就把两个环境的镜像搞定的，因此权衡之后使用两套文件：Dockerfile & docker-compose.yaml、Dockerfile.dev & docker-compose.dev.yaml 来应对不同环境。

[参考1](https://medium.com/@basi/docker-compose-from-development-to-production-88000124a57c)
[参考2](https://blog.codeship.com/using-docker-compose-for-nodejs-development/)
[参考3](http://jdlm.info/articles/2016/03/06/lessons-building-node-app-docker.html)

### CI

如果没有 CI, 那么开发部署流程大概是这样：开发完毕; build 镜像并推到 image hub; 登录到远程主机；在远程主机上拉取 image 并通过合适的 docker-compose.yaml 开启服务。这个流程虽然行的通，但是有一定的弊端：每次想部署都要自己手动 build & push; 在多人协作的过程时，仍需要 git 等代码管理工具；需要对推送到 hub 设置一定的权限控制；缺乏代码审查等。因此还是需要一个自动化的过程，让开发不用或者不需要过多的关注开发之外的事情。Github、Gitlab 以及 Jenkins 等都对 docker 的持续集成分发有相关功能支持，在此就不详细复制粘贴了。