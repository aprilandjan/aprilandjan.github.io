---
layout: post
title:  working-with-docker
date:   2018-02-22 15:16:00 +0800
categories: docker
---

在容器越来越流行的今天，了解下如何使用 Docker 将 node 服务容器化部署是很有必要的。关于 docker 的基础命令等内容在此不再赘述，主要是结合实际需求简单介绍如何把容器化配置加入到现有的 node 项目中。

## 开发环境

开发环境下需求点在于：

1. 启动项目需要的全部服务(node, mysql, redis)；
2. 监听代码更改 & 重启服务。

可以通过编写文 `docker-compose.yaml`  依次启动多个服务的容器实例并串联。不过在这之前，因为正在开发的 node 项目还没有容器化，需要先写一份容器化配置文件 `Dockerfile.dev`：

```
# Dockerfile.dev

FROM node:carbon
 
WORKDIR /app
 
# 安装依赖需要的相关文件
COPY package*.json .npmrc /app/
 
# install all dependencies
RUN npm install
 
# just a remark
EXPOSE 7001
 
CMD ["npm", "run", "docker-dev"]
```

说明：

1. node:carbon` 是源镜像，`carbon` 是 tag/版本名，一般应该选择 LTS(Long Term Support) 版本的 node 镜像。可以在 这里 看到全部可用的 node 镜像;
2. 开发环境下只需要拷贝控制依赖的相关文件 (package.json, package-lock.json, yarn-lock.json, .npmrc)的文件。文件 .npmrc 的目的在于配置 npm 如何下载依赖，可以解决 cnpm 来源的依赖下载问题。例如：

    ```
    registry=https://registry.npmjs.org
    @scope:registry=private-cnpm-registry
    ```
3. 镜像的 entrypoint 设置为一条 npm 指令，当镜像容器运行之后会执行该指令开启服务。

现在可以通过 `docker-compose.yaml` 串联 node、mysql、redis 三个服务了：

```
# Docker-compose.yaml
version: "3"
services:
  mysql:
    image: mysql:latest
    container_name: mysql
    environment:
      - MYSQL_DATABASE=user
      - MYSQL_ROOT_PASSWORD=root
    ports:
      - 3306:3306
  redis:
    image: redis:latest
    container_name: redis
    ports:
      - 6379:6379
  node:
    build:
      context: .
      dockerfile: Dockerfile.dev
    environment:
      # NODE_ENV=development
    depends_on:
      - mysql
      - redis
    volumes:
      - .:/app/
      - /app/node_modules
    ports:
      - 7001:7001
```

说明：
1. 如果本地没有某指定的镜像（例如 image: mysql:latest），会从 docker hub 上下载相应的镜像到本地；如果指定某服务的镜像需要 build 生成，会尝试根据 build 参数先 build 成镜像再启动服务;
2. 通过 ports 参数将容器内服务的端口映射到宿主环境的端口上，这样可以在宿主环境（localhost) 上直接访问这些端口;
3. mysql 以及 redis 都设定了 `container_name`，使得 node 容器内部可以通过这两个容器名找到其它容器的地址，从而进行连接;
4. node 容器通过 `volumes` 设定目录挂载卷，使得宿主环境与容器内的对应目录内的文件保持同步(参考)，这样当在宿主环境下编辑源代码，容器内的文件也会同步变更；再通过一些工具（例如 nodemon）可以实现监听文件变更&重启服务的功能。

有了这个配置文件，就可以通过 docker-compose 一键启动服务了:

```bash
docker-compose up
```

## 调试环境

对 node 程序进行调试的基本方法是使用额外调试参数(`–inspect` 设定输出调试信息地址及端口; `--nolazy` 以非 lazy 模式启动便于实时断点调试)启动程序，监听调试输出信息，交给调试工具(chrome debug tool, vscode debugger 或者其它 IDE 调试工具) 输出。node 服务容器化之后，为了能采集到来自容器内 node 程序的调试信息，需要在容器上暴露额外的调试端口给宿主，再监听调试信息。以下是调试环境下的 compose 配置文件 `docker-compose.debug.yaml`:

```
# docker-compose.debug.yaml
version: "3"
# all other configs come from base config
services:
  node:
    # override existed command
    command: npm run docker-debug
    ports:
      # debug port
      - 9999:9999
```

说明：
1. 这份配置不是单独使用的，需要在默认配置文件 `docker-compose.yaml` 的基础上合并使用。docker-compose 指令支持多配置文件复合 ([参考](https://docs.docker.com/compose/extends/))；
2. 通过 `command` 覆盖了容器默认的 entrypoint，实现以调试模式启动 node 程序;
3. 增加调试信息输出的端口 `9999`

如果使用 vscode 作为编辑器，可以在工程内定义以下调试任务配置([参考](https://github.com/Microsoft/vscode-recipes/tree/master/Docker-TypeScript))：

```
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Docker Debug",
      "type": "node",
      "request": "launch",
      "cwd": "${workspaceRoot}",
      "runtimeExecutable": "docker-compose",
      "runtimeArgs": [ "-f", "docker-compose.yml", "-f", "docker-compose.debug.yml", "up"],
      "restart": true,
      "port": 9999,
      "timeout": 60000,
      "localRoot": "${workspaceRoot}",
      "remoteRoot": "/app",
      "outFiles": [
        "${workspaceRoot}/dist/**/*.js"
      ],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    }
  ]
}
```

配置完成之后，进入 vscode  调试面板，启动 `Docker Debug`  任务即可，支持实时断点、代码更新服务重启等。需要说明的是，如果代码变更导致镜像内服务重启了，调试进程的端口可能会发生变化进而导致调试器无法连接到配置中指定开放的端口；有一些模块有针对调试模式做一层代理，把调试进程的信息抓取到指定端口输出，从而避免该问题。

## 测试环境

单元测试环境相对于开发环境只是在服务都已经建立的情况下执行的入口程序不同 (`npm run dev` => `npm run test`)，我们可以另外写一份 `docker-compoe.test.yaml` 改变默认的 node 镜像入口程序，然后使用复合配置文件的 docker-compose  命令启动测试:

```bash
docker-compose -f docker-compose.yaml -f docker-compose.test.yaml up
```

这样会像开发环境一样启动各个服务镜像，伴随着测试结果成功或失败。但单元测试命令本身并不是一个持久的服务，用 `docker-compose run` 命令执行一次性的测试命令([参考](https://stackoverflow.com/questions/33066528/should-i-use-docker-compose-start-up-or-run))得到结果会更好，也可以省掉额外加一个配置文件:

```bash
docker-compose run node npm run test
```

说明：
1. `node` 是在默认配置文件 `docker-compose.yaml` 中定义的 node 服务名称；
2. 命令 `npm run test` 会覆盖掉 node 服务里定义的 entrypoint，执行结束后退出所有服务。

除了单元测试，可能还需要针对 build 之后的 node 服务镜像的集成测试，暂且略过。

## 镜像 Build & Push

现在已经在开发环境有一个 node 的镜像了。但是它并不是完整独立的 node 服务,  并且有许多 release 环境下冗余的依赖和系统配置，因此需要为部署单独准备一份发行版的镜像。编写配置文件如下：

```
# Dockerfile
# ----- build with carbon -----
FROM node:carbon AS build
 
 
WORKDIR /app
 
COPY package*.json .npmrc ./
 
# install only production dependencies
RUN npm install --only-production
 
# copy production dependencies aside
RUN cp -R node_modules prod_node_modules
 
# install all dependencies
RUN npm install
 
COPY . .
 
# build files
RUN npm run tsc
 
# ----- release with alpine -----
FROM node:carbon-alpine AS release
 
# install curl
RUN apk add --no-cache --update curl
 
WORKDIR /app
 
# copy everything needed from base
COPY --from=build /app/prod_node_modules node_modules
COPY --from=build /app/app app
COPY --from=build /app/config config
COPY --from=build /app/app.js /app/package.json ./
 
CMD ["npm", "run", "start"]
```

说明：
1. 整个配置采用多阶段配置([multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/)) ，首先基于 node:carbon 安装依赖、编译源文件(ts => js)，再基于 node:alpine 打包服务运行所需的必要文件；
2. node:alpine 相比 node:carbon 体积精简很多(60M+ vs 600M+)，镜像中默认没有一些系统工具(curl, git, make, gcc 等), 因此如果自己的服务要用到这种工具，需要额外通过 `apk add` 安装;
3. 只将服务运行需要的必要文件(production only 的 node_modules，编译后的代码，相关配置) 放入最终的容器中，减小镜像体积。

把 node 服务  build 成镜像：

```bash
docker build -t your-space/project-name .
```

成功之后可以运行以下命令单独跑一下此镜像看看服务是否正确打包了(虽然很可能因缺少db等的配置而启动失败)：

```bash
docker run --rm -it your-space/project-name
```

之后可以根据运维提供的流程，打上合适的 TAG 推送到私有hub了：

```bash
dockker tag your-space/project-name your-hub/your-space/project-name:0.0.1
docker push your-hub/your-space/project-name:0.0.1
```

## 部署

编写合适的  `docker-compose.yaml` 文件并部署到服务器上用 Docker 启动。