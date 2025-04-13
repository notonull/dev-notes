---
title: 【Linux】【Docker】【Nginx】Nginx服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - nginx
---

## 内容

### 1.镜像获取

#### 1.1.查询docker hub镜像

```bash
sudo docker search nginx
```

#### 1.2.拉取镜像

```bash
sudo docker pull nginx
```

#### 1.3.查看本地镜像

```bash
sudo docker images
```

### 2.环境准备

#### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p /opt/app/nginx
sudo mkdir -p /opt/app/nginx/conf
sudo mkdir -p /opt/app/nginx/logs
sudo mkdir -p /opt/app/nginx/html
```

### 3.启动镜像

#### 3.1.运行镜像

```shell
sudo docker run -d \
  --name nginx \
  -p 80:80 \
  -p 443:443 \
  -v /opt/app/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
  -v /opt/app/nginx/conf/conf.d:/etc/nginx/conf.d \
  -v /opt/app/nginx/logs:/var/log/nginx \
  -v /opt/app/nginx/html:/usr/share/nginx/html \
  --restart always \
  nginx:latest
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

| 参数                                                      | 描述                             |
| --------------------------------------------------------- | -------------------------------- |
| `-d`                                                      | 后台运行容器                     |
| `--name nginx`                                            | 容器命名为 nginx                 |
| `-p 80:80`                                                | 映射 80 端口                     |
| `-p 443:443`                                              | 映射 443 端口                    |
| `-v /opt/app/nginx/conf/nginx.conf:/etc/nginx/nginx.conf` | 映射主配置文件                   |
| `-v /opt/app/nginx/conf/conf.d:/etc/nginx/conf.d`         | 映射子配置目录（多站点配置）     |
| `-v /opt/app/nginx/logs:/var/log/nginx`                   | 映射日志目录                     |
| `-v /opt/app/nginx/html:/usr/share/nginx/html`            | 映射网页目录                     |
| `--restart always`                                        | 容器意外停止或系统重启时自动启动 |
| `nginx:latest`                                            | 使用 nginx:latest 镜像           |

### 4.后续配置

#### 4.1. 配置conf

[【Nginx】conf配置模板](../代码模板/【Nginx】conf配置模板.md)

### 常用命令

```markdown
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

