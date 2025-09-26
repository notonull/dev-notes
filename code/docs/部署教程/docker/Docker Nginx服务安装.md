---
title: Docker Nginx服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - nginx
createTime: 2025/04/12 17:00:02
permalink: /blog/rek825cy/
---

## 参考

[官方地址](https://www.docker.com/)

[官方文档地址](https://docs.docker.com/)

[docker hub](https://hub.docker.com/)

## 1.镜像获取

### 1.1.查询docker hub镜像

```bash
sudo docker search nginx
```

### 1.2.拉取镜像

```bash
sudo docker pull nginx:latest
```

### 1.3.查看本地镜像

```bash
sudo docker images
```

## 2.环境准备
### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p /opt/server/nginx
sudo mkdir -p /opt/server/nginx/conf
sudo mkdir -p /opt/server/nginx/logs
sudo mkdir -p /opt/server/nginx/html
```

### 2.2. 新增nginx.conf

```bash
vim /opt/server/nginx/conf/nginx.conf
```

### 2.3. 配置nginx.conf

[【Nginx】conf配置模板](../../代码模板/Nginx%20conf配置模板.md)

## 3.启动镜像

### 3.1.运行镜像
#### 3.1.1.docker run 运行

```shell
sudo docker run -d \
  --name nginx \
  -p 80:80 \
  -p 443:443 \
  -v /opt/server/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
  -v /opt/server/nginx/conf/conf.d:/etc/nginx/conf.d \
  -v /opt/server/nginx/logs:/var/log/nginx \
  -v /opt/server/nginx/html:/usr/share/nginx/html \
  --restart unless-stopped \
  nginx:latest
```
#### 3.1.2.docker compose 运行

```bash
## 切换目录
cd /opt/server/nginx
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
  nginx:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /opt/server/nginx/conf/nginx.conf:/etc/nginx/nginx.conf
      - /opt/server/nginx/conf/conf.d:/etc/nginx/conf.d
      - /opt/server/nginx/logs:/var/log/nginx
      - /opt/server/nginx/html:/usr/share/nginx/html
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

| 参数                                                         | 描述                             |
| ------------------------------------------------------------ | -------------------------------- |
| `-d`                                                         | 后台运行容器                     |
| `--name nginx`                                               | 容器命名为 nginx                 |
| `-p 80:80`                                                   | 映射 80 端口                     |
| `-p 443:443`                                                 | 映射 443 端口                    |
| `-v /opt/server/nginx/conf/nginx.conf:/etc/nginx/nginx.conf` | 映射主配置文件                   |
| `-v /opt/server/nginx/conf/conf.d:/etc/nginx/conf.d`         | 映射子配置目录（多站点配置）     |
| `-v /opt/server/nginx/logs:/var/log/nginx`                   | 映射日志目录                     |
| `-v /opt/server/nginx/html:/usr/share/nginx/html`            | 映射网页目录                     |
| `--restart unless-stopped`                                   | 容器意外停止或系统重启时自动启动 |
| `nginx:latest`                                               | 使用 nginx:latest 镜像           |

## 4.后续配置

[【Nginx】conf配置模板](../../代码模板/Nginx%20conf配置模板.md)

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

