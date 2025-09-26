---
title: Docker Minio服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - minio
createTime: 2025/09/14 17:56:00
permalink: /blog/dhvz7h70/
---

## 参考

[官方地址](https://www.docker.com/)

[官方文档地址](https://docs.docker.com/)

[docker hub](https://hub.docker.com/)

## 1.镜像获取

### 1.1.查询docker hub镜像

```bash
sudo docker search minio
```

### 1.2.拉取镜像

```bash
sudo docker pull minio/minio:latest
```

### 1.3.查看本地镜像

```bash
sudo docker images
```

## 2.环境准备
### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p /opt/server/minio
sudo mkdir -p /opt/server/minio/data
sudo mkdir -p /opt/server/minio/config
```

## 3.启动镜像

### 3.1.运行镜像
#### 3.1.1.docker run 运行

```shell
sudo docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9090:9090 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD='123456' \
  -v /opt/server/minio/data:/data \
  -v /opt/server/minio/config:/root/.minio \
  --restart unless-stopped \
  minio/minio:latest \
  server /data --console-address ":9090"
```
#### 3.1.2.docker compose 运行

```bash
## 切换目录
cd /opt/server/minio
## 设置docker compose yml
vim docker-compose.yml
## 后台启动
docker compose up -d
## 关闭销毁
docker compose down
```

**docker-compose.yml**

```yaml
version: "3.9"

services:
  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9090:9090"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: 123456
    volumes:
      - /opt/server/minio/data:/data
      - /opt/server/minio/config:/root/.minio
    command: server /data --console-address ":9090"
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

| 参数                                       | 描述                                   |
| ------------------------------------------ | -------------------------------------- |
| `-d`                                       | 后台运行容器                           |
| `--name minio`                             | 容器命名为 minio                       |
| `-p 9000:9000`                             | 映射 MinIO 服务端口                    |
| `-p 9090:9090`                             | 映射 MinIO 控制台端口                  |
| `-e MINIO_ROOT_USER=admin`                 | 设置 MinIO 根用户                      |
| `-e MINIO_ROOT_PASSWORD='123456'`          | 设置 MinIO 根用户密码                  |
| `-v /opt/server/minio/data:/data`          | 挂载 MinIO 数据目录                    |
| `-v /opt/server/minio/config:/root/.minio` | 挂载 MinIO 配置目录                    |
| `--restart unless-stopped`                 | 容器意外停止或系统重启时自动启动       |
| `minio/minio:latest`                       | 使用 MinIO 官方镜像                    |
| `server /data --console-address ":9090"`   | 容器启动命令，启动服务并设置控制台端口 |

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

