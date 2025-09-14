---
title: 【Linux】【Docker】【Nacos】Nacos服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - nacos
createTime: 2025/09/14 18:05:33
permalink: /blog/egf5xnes/
---

## 1.镜像获取

### 1.1.查询docker hub镜像

```bash
sudo docker search nacos
```

### 1.2.拉取镜像

```bash
sudo docker pull nacos/nacos-server:latest
```

### 1.3.查看本地镜像

```bash
sudo docker images
```

## 2.环境准备
### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p /opt/server/nacos
sudo mkdir -p /opt/server/nacos/data
sudo mkdir -p /opt/server/nacos/logs
```

## 3.启动镜像

### 3.1.运行镜像
#### 3.1.1.docker run 运行

```shell
sudo docker run -d \
  --name nacos \
  -p 9080:8080 \
  -p 8848:8848 \
  -p 9848:9848 \
  -e MODE=standalone \
  -e SPRING_DATASOURCE_PLATFORM=mysql \
  -e MYSQL_SERVICE_HOST=192.168.1.12 \
  -e MYSQL_SERVICE_DB_NAME=nacos \
  -e MYSQL_SERVICE_PORT=3306 \
  -e MYSQL_SERVICE_USER=root \
  -e MYSQL_SERVICE_PASSWORD=123456 \
  -e MYSQL_SERVICE_DB_PARAM='characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true' \
  -e NACOS_AUTH_TOKEN=WDdrUHFYOXZWMnJZOFRXOEZuTDZOQXhQd0I1Y0gxZFEyeEE5ZVI0dU04aUs3b1AzdyN2TjJsVjBqRzVmVA== \
  -e NACOS_AUTH_IDENTITY_KEY=nacos \
  -e NACOS_AUTH_IDENTITY_VALUE=nacos \
  -v /opt/server/nacos/data:/home/nacos/nacos-data \
  -v /opt/server/nacos/logs:/home/nacos/logs \
  --restart unless-stopped \
  nacos/nacos-server:latest

```
#### 3.1.2.docker compose 运行

```bash
## 切换目录
cd /opt/server/nacos
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
  nacos:
    image: nacos/nacos-server:latest
    container_name: nacos
    environment:
      - MODE=standalone
      - SPRING_DATASOURCE_PLATFORM=mysql
      - MYSQL_SERVICE_HOST=192.168.1.12
      - MYSQL_SERVICE_DB_NAME=nacos
      - MYSQL_SERVICE_PORT=3306
      - MYSQL_SERVICE_USER=root
      - MYSQL_SERVICE_PASSWORD=123456
      - MYSQL_SERVICE_DB_PARAM=characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
      - NACOS_AUTH_TOKEN=WDdrUHFYOXZWMnJZOFRXOEZuTDZOQXhQd0I1Y0gxZFEyeEE5ZVI0dU04aUs3b1AzdyN2TjJsVjBqRzVmVA==
      - NACOS_AUTH_IDENTITY_KEY=nacos
      - NACOS_AUTH_IDENTITY_VALUE=nacos
    ports:
      - "9080:8080"   # 内部 API（可选）
      - "8848:8848"   # 控制台 / 配置中心 / 服务发现
      - "9848:9848"   # gRPC 通道
    volumes:
      - /opt/server/nacos/data:/home/nacos/nacos-data
      - /opt/server/nacos/logs:/home/nacos/logs
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

| 参数                                               | 描述                                 |
| -------------------------------------------------- | ------------------------------------ |
| `-d`                                               | 后台运行容器                         |
| `--name nacos`                                     | 容器命名为 nacos                     |
| `-p 9080:8080`                                     | 映射内部 API 端口（可选）            |
| `-p 8848:8848`                                     | 映射控制台 / 配置中心 / 服务发现端口 |
| `-p 9848:9848`                                     | 映射 gRPC 通道端口                   |
| `-e MODE=standalone`                               | 设置 Nacos 运行模式为单机模式        |
| `-e SPRING_DATASOURCE_PLATFORM=mysql`              | 设置数据库类型为 MySQL               |
| `-e MYSQL_SERVICE_HOST=192.168.1.12`               | 设置 MySQL 服务主机地址              |
| `-e MYSQL_SERVICE_DB_NAME=nacos`                   | 设置 MySQL 数据库名称                |
| `-e MYSQL_SERVICE_PORT=3306`                       | 设置 MySQL 服务端口                  |
| `-e MYSQL_SERVICE_USER=root`                       | 设置 MySQL 用户名                    |
| `-e MYSQL_SERVICE_PASSWORD=123456`                 | 设置 MySQL 用户密码                  |
| `-e MYSQL_SERVICE_DB_PARAM='...'`                  | 设置 MySQL 连接参数                  |
| `-e NACOS_AUTH_TOKEN=...`                          | 设置 Nacos 访问令牌                  |
| `-e NACOS_AUTH_IDENTITY_KEY=nacos`                 | 设置 Nacos 认证 Key                  |
| `-e NACOS_AUTH_IDENTITY_VALUE=nacos`               | 设置 Nacos 认证 Value                |
| `-v /opt/server/nacos/data:/home/nacos/nacos-data` | 挂载 Nacos 数据目录                  |
| `-v /opt/server/nacos/logs:/home/nacos/logs`       | 挂载 Nacos 日志目录                  |
| `--restart unless-stopped`                         | 容器意外停止或系统重启时自动启动     |
| `nacos/nacos-server:latest`                        | 使用 Nacos 官方最新镜像              |

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

