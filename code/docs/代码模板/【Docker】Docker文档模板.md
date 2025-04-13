---
title: 【Docker】Docker文档模板
copyright: CC-BY-4.0
tags:
  - 模板
  - docker
createTime: 2025/04/12 19:00:24
permalink: /blog/sh70nkiv/
---

## 内容

### 1.镜像获取

#### 1.1.查询docker hub镜像

```bash
sudo docker search #镜像
```

#### 1.2.拉取镜像

```bash
sudo docker pull #镜像
```

#### 1.3.查看本地镜像

```bash
sudo docker images
```

### 2.环境准备

#### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p #路径
```

### 3.启动镜像

#### 3.1.运行镜像

```bash
sudo docker run ...
```

#### 3.2.参数解释

| 指令        | 描述     |
| ----------- | -------- |
| `-d`        | 后台运行 |
| `-name`     | 容器名称 |
| `-e`        | 容器环境 |
| `-p`        | 映射端口 |
| `-v`        | 卷挂载   |
| `--restart` | 重启策略 |

### 4.后续配置

#### 4.1. 其他操作

```bash
## 其他操作
```

### 常用命令

```bash
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
```

