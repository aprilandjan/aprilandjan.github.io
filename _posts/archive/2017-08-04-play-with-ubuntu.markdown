---
layout: post
title:  play-with-ubuntu
date:   2017-08-04 22:11:00 +0800
categories: linux
---

去年买的一年期域名都快过期了，一直也没怎么好好利用。最近在 DigitalOcean 上开了个VPS，打算再重新整理一下。这次选的系统是 `ubuntu 16`，因为听说对 linux 不熟悉的人，用 `ubuntu` 会是最好的选择。下面记录一下折腾的全过程。

# 查看系统版本

```
lsb_release -a
```

# 查询某服务的运行状态

```
systemctl status <service_name>
```

# ssh

在 DigitalOcean 页面上创建好 Droplet (水滴, 很形象的一个词) 之后，DigitalOcean 会往邮箱里发送初始的密码。在本地可以通过 `ssh root@your.ip.address.here` 的方式连接到远程主机，连上去之后会要求输入初始密码，并会要求更改初始密码。之后可以配置 ssh key 来快速连接，方式如下：

- 在本机生成一对 ssh 公私钥：

    ```bash
    ssh-keygen -t rsa
    ```

- 如果没有修改生成的文件路径和文件名，应该是在本机当前用户目录(即 `~`)的隐藏文件夹 `.ssh` 之内，公钥是 `id_rsa.pub`, 私钥是 `id_rsa`。接下来不管用哪种方式把公钥写入到远程主机 `~/.ssh/` 目录下的 `authorized_keys` 文件内(如果文件不存在可以自己手动创建)。这个文件是 ssh 登陆用来验证已授权秘钥的，如果以后还要加其它的连接访问设备，也可以同样的方式写入更多公钥。例如：

    ```bash
    cat ~/.ssh/id_rsa.pub | ssh root@[your.ip.address.here] "cat >> ~/.ssh/authorized_keys"
    ```

- 在此之后，可以已经可以通过 `ssh root@[your.ip.address.here]` 的命令免密登陆远程主机了。但是每次都要输入用户名和 IP 地址不太方便，因此我们在本机创建修改 `~/.ssh/config` 文件用以配置 ssh 登录的信息，给远程主机起一个便于识别的别名，方便日后登录：

    ```bash ~/.ssh/config
    Host my-droplet
        HostName [your.ip.address.here]
        User root
        IdentityFile ~/.ssh/id_rsa
    ```

大功告成！之后再登录只需要简单的 `ssh my-droplet` 就可以了！

# git

配置  git 代码访问权限这个就不仔细说了。在远程主机上用 `ssh-keygen` 生成公私钥对，然后把公钥加到自己 git 账号下。如果有多个不同的 git(gitlab, github等)，可以通过修改 `~/.ssh/config` 文件告诉 ssh 命令，对不同的 git 使用不同的帐号和私钥。例如：

```
Host 	github.com
    HostName        github.com
    User aprilandjan
    IdentityFile    ~/.ssh/id_rsa_github

Host    gitlab.my-corp.com
    HostName	    gitlab.my-corp.com
    User merlin.ye
    IdentityFile    ~/.ssh/id_rsa_my-corp
```

# nginx

安装过程基本参照 [https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04) 来操作。

# mongo

安装过程基本参照 [https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-16-04) 来设置，在此不再赘述。