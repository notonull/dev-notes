---
title: 【Linux】【Docker】【YApi】YApi服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - yapi
createTime: 2025/09/14 18:14:35
permalink: /blog/ct0sqi0x/
---

## 1.镜像获取

### 1.1.查询docker hub镜像

```bash
sudo docker search yapi
```

### 1.2.拉取镜像

```bash
sudo docker pull jayfong/yapi:latest
```

### 1.3.查看本地镜像

```bash
sudo docker images
```

## 2.环境准备
### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p /opt/server/yapi
```

## 3.启动镜像

### 3.1.运行镜像
#### 3.1.1.docker run 运行

```shell
sudo docker run -d \
  --name yapi \
  -p 3000:3000 \
  -e YAPI_ADMIN_ACCOUNT=admin@yapi.com \
  -e YAPI_ADMIN_PASSWORD=123456 \
  -e YAPI_CLOSE_REGISTER=true \
  -e YAPI_DB_SERVERNAME=192.168.1.12 \
  -e YAPI_DB_PORT=27017 \
  -e YAPI_DB_DATABASE=yapi \
  -e YAPI_DB_USER=root \
  -e YAPI_DB_PASS=123456 \
  -e YAPI_DB_AUTH_SOURCE=admin \
  --restart unless-stopped \
  jayfong/yapi:latest
```
#### 3.1.2.docker compose 运行

```bash
## 切换目录
cd /opt/server/yapi
## 设置docker compose yml
vim docker-compose.yml
## 后台启动
docker compose up -d
## 关闭销毁
docker compose down
```

**docker-compose.yml**

```yaml
version: '3.9'

services:
  yapi-web:
    image: jayfong/yapi:latest
    container_name: yapi
    ports:
      - 3000:3000
    environment:
      - YAPI_ADMIN_ACCOUNT=admin@yapi.com 
      - YAPI_ADMIN_PASSWORD=123456
      - YAPI_CLOSE_REGISTER=true
      - YAPI_DB_SERVERNAME=192.168.1.12
      - YAPI_DB_PORT=27017
      - YAPI_DB_DATABASE=yapi
      - YAPI_DB_USER=root
      - YAPI_DB_PASS=123456
      - YAPI_DB_AUTH_SOURCE=admin
    restart: unless-stopped
```

### 3.2.参数解释

| 指令        | 描述     |
| ----------- | -------- |
| `-d`        | 后台运行 |
| `-name`     | 容器名称 |
| `-e`        | 容器环境 |
| `-p`        | 映射端口 |
| `-v`        | 卷挂载   |
| `--restart` | 重启策略 |

| 参数                                   | 描述                             |
| -------------------------------------- | -------------------------------- |
| `-d`                                   | 后台运行容器                     |
| `--name yapi`                          | 容器命名为 yapi                  |
| `-p 3000:3000`                         | 映射 YApi Web 管理端口           |
| `-e YAPI_ADMIN_ACCOUNT=admin@yapi.com` | 设置 YApi 管理员账号             |
| `-e YAPI_ADMIN_PASSWORD=123456`        | 设置 YApi 管理员密码             |
| `-e YAPI_CLOSE_REGISTER=true`          | 关闭注册功能                     |
| `-e YAPI_DB_SERVERNAME=192.168.1.12`   | 设置 MongoDB 服务器地址          |
| `-e YAPI_DB_PORT=27017`                | 设置 MongoDB 端口                |
| `-e YAPI_DB_DATABASE=yapi`             | 设置 YApi 数据库名称             |
| `-e YAPI_DB_USER=root`                 | 设置 MongoDB 用户名              |
| `-e YAPI_DB_PASS=123456`               | 设置 MongoDB 密码                |
| `-e YAPI_DB_AUTH_SOURCE=admin`         | 设置 MongoDB 认证数据库          |
| `--restart unless-stopped`             | 容器意外停止或系统重启时自动启动 |
| `jayfong/yapi:latest`                  | 使用 YApi 官方最新镜像           |

## 4.后续配置



## 常用命令

```markdown
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
## cd到docker-compose.yml所在目录
## 启动服务（后台模式）
docker compose up -d
## 启动服务（前台模式，日志直接输出）
docker compose up
## 停止服务
docker compose down
## 仅停止服务，不删除网络或卷
docker compose stop
## 启动已停止的服务
docker compose start
## 重启服务
docker compose restart
```

