---
title: 【Linux】【Docker】Docker服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - ubunto
  - openEuler
  - docker
createTime: 2025/03/18 09:00:00
updateTime: 2025/04/12 19:11:00
permalink: /blog/mpqs2g9m/
---

## 1.参考

**官方地址:**
http://test.com

**官方下载地址:**
http://test.com/en/download.html

**官方文档**
http://test.com/

## 2.安装服务

### 2.1.apt安装

#### 2.1.1.更新软件源

```bash
sudo apt update
sudo apt upgrade
```

#### 2.1.2.安装依赖

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common
```

#### 2.1.3.使用阿里云Docker CE仓库GPG密钥

```bash
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
```

#### 2.1.4.添加阿里云的仓库

```bash
sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
```

#### 2.1.5.再次更新软件源

```BASH
sudo apt update
sudo apt upgrade
```

#### 2.1.6.安装docker

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

| 指令                    | 描述                                         |
| ----------------------- | -------------------------------------------- |
| `docker-ce`             | Docker Community Edition（社区版）的核心部分 |
| `docker-ce-cli`         | Docker 命令行接口（CLI）                     |
| `containerd.io`         | 管理容器的生命周期                           |
| `docker-buildx-plugin`  | 增强的构建工具插件                           |
| `docker-compose-plugin` | 管理和运行多容器应用插件                     |

### 2.2.dnf安装

#### 2.2.1.更新软件源

```
sudo dnf update -y
```

#### 2.2.2.安装依赖

安装所需的软件包以便使用 `Docker CE` 存储库

```bash
sudo dnf install -y dnf-plugins-core
```

#### 2.2.3.添加 Docker CE 存储库

```bash
sudo dnf config-manager --add-repo=https://repo.huaweicloud.com/docker-ce/linux/centos/docker-ce.repo
```

#### 2.2.4.docker-ce.repo 备份

```bash
cp -r /etc/yum.repos.d/docker-ce.repo /etc/yum.repos.d/docker-ce.repo.bak
```

#### 2.2.5.docker-ce.repo 替换为华为开源镜像源

```bash
sed -i 's+download.docker.com+repo.huaweicloud.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
```

#### 2.2.6.docker-ce.repo 修改版本号

说明：`docker-ce.repo` 中用 `$releasever` 变量代替当前系统的版本号，该变量在 `CentOS` 中有效，但在 `openEuler` 中无效，所以将该变量直接改为`8`。

```bash
sed -i 's+$releasever+8+'  /etc/yum.repos.d/docker-ce.repo
```

#### 2.2.7.更新索引缓存并安装 Docker CE

```bash
dnf makecache
```

#### 2.2.8.安装docker

```bash
sudo dnf install -y docker-ce docker-ce-cli containerd.io
```

```bash
dnf install -y docker-compose-plugin
```

| 指令                    | 描述                                         |
| ----------------------- | -------------------------------------------- |
| `docker-ce`             | Docker Community Edition（社区版）的核心部分 |
| `docker-ce-cli`         | Docker 命令行接口（CLI）                     |
| `containerd.io`         | 管理容器的生命周期                           |
| `docker-buildx-plugin`  | 增强的构建工具插件                           |
| `docker-compose-plugin` | 管理和运行多容器应用插件                     |

### 2.2.yum安装

同2.2.dnf安装

## 3.后续配置

### 3.1.daemon.json

```bash
sudo vim /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [
  		"https://docker.1ms.run/"
  		"https://docker.xuanyuan.me/"
    ]
}
EOF
```

### 3.1.docker启动

```bash
# 开机自启动
systemctl enable docker
# 重新加载配置
systemctl daemon-reload
# 启动
systemctl start docker
# 重启
systemctl restart docker
# 停止
systemctl start docker
```



### 3.1.DockerHub

**国内DockerHub因不知名原因无法访问，各大互联网服务相继关停，目前只能尝试不断更新镜像站源**

```bash
### 长期更新地址（202502）
https://zhuanlan.zhihu.com/p/24461370776
https://cloud.tencent.com/developer/article/2485043
### 长期更新地址（202509）
https://github.com/dongyubin/DockerHub
```

### 3.2.配置镜像源列表

```bash
sudo vim /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [
        "https://docker.1ms.run",
        "https://docker.xuanyuan.me"
    ]
}
EOF
```

## 常用命令

```bash
# docker命令
## 查看所有容器
docker ps -a
## 查看所有镜像
docker images
## 查看容器日志
docker logs [容器ID或容器名]
## 删除容器
docker rm [容器ID或容器名]
## 删除镜像
docker rmi [镜像ID]
## 停止容器
docker stop [容器ID或容器名]
## 启动容器
docker start [容器ID或容器名]

# docker compose命令
# 启动服务（后台模式）
docker compose up -d
# 启动服务（前台模式，日志直接输出）
docker compose up
# 停止服务
docker compose down
# 仅停止服务，不删除网络或卷
docker compose stop
# 启动已停止的服务
docker compose start
# 重启服务
docker compose restart
```