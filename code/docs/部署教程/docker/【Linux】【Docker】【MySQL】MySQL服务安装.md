---
title: 【Linux】【Docker】【MySQL】MySQL服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - mysql
createTime: 2025/03/18 09:00:00
updateTime: 2025/04/12 18:59:00
permalink: /blog/zpxci6jd/

---

## 1.镜像获取

### 1.1.查询docker hub镜像

```bash
sudo docker search mysql
```

### 1.2.拉取镜像

```bash
## 本次演示 mysql:8.0.16
sudo docker pull mysql:8.0.16
```

### 1.3.查看本地镜像

```bash
sudo docker images
```

## 2.环境准备

### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p /opt/server/mysql
sudo mkdir -p /opt/server/mysql/conf
sudo mkdir -p /opt/server/mysql/data
sudo mkdir -p /opt/server/mysql/logs
```

### 2.2.新增my.conf

```bash
sudo vim /opt/server/mysql/conf/my.cnf
```

### 2.3.配置my.conf

```markdown
[client]
#设置客户端默认字符集utf8mb4
default-character-set=utf8mb4
[mysql]
#设置服务器默认字符集为utf8mb4
default-character-set=utf8mb4
[mysqld]
#配置服务器的服务号，具备日后需要集群做准备
server-id = 1
# 开启MySQL数据库的二进制日志，用于记录用户对数据库的操作SQL语句，具备日后需要集群做准备
# log-bin=mysql-bin
#设置清理超过30天的日志，以免日志堆积造过多成服务器内存爆满。2592000秒等于30天的秒数
binlog_expire_logs_seconds = 2592000
#解决MySQL8.0版本GROUP BY问题
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
#允许最大的连接数
max_connections=1000
# 禁用符号链接以防止各种安全风险
symbolic-links=0
# 设置东八区时区
default-time_zone = '+8:00'
```

## 3.启动镜像

### 3.1.运行镜像

#### 3.1.1.docker run 运行

```shell
sudo docker run -d \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -p 3306:3306 \
  -v /opt/server/mysql/data:/var/lib/mysql \
  -v /opt/server/mysql/mysql-files:/var/lib/mysql-files \
  -v /opt/server/mysql/conf/my.cnf:/etc/mysql/my.cnf \
  -v /opt/server/mysql/logs:/var/log/mysql \
  --restart unless-stopped \
  mysql:8.0.16
```

#### 3.1.2.docker compose 运行

```bash
## 切换目录
cd /opt/server/mysql
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
  mysql:
    image: mysql:8.0.16
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: 123456
    ports:
      - "3306:3306"
    volumes:
      - /opt/server/mysql/data:/var/lib/mysql
      - /opt/server/mysql/mysql-files:/var/lib/mysql-files
      - /opt/server/mysql/conf/my.cnf:/etc/mysql/my.cnf
      - /opt/server/mysql/logs:/var/log/mysql
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

| 参数                                                    | 说明                             |
| ------------------------------------------------------- | -------------------------------- |
| `-d`                                                    | 后台运行容器                     |
| `--name mysql`                                          | 容器命名为 mysql8.0              |
| `-e MYSQL_ROOT_PASSWORD=123456`                         | 设置 root 用户密码为 123456      |
| `-p 3306:3306`                                          | 映射 3306 端口（MySQL 默认端口） |
| `-v /opt/server/mysql/data:/var/lib/mysql`              | 映射数据目录（数据库数据持久化） |
| `-v /opt/server/mysql/mysql-files:/var/lib/mysql-files` | 映射变量目录                     |
| `-v /opt/server/mysql/conf/my.cnf:/etc/mysql/my.cnf`    | 映射主配置文件                   |
| `-v /opt/server/mysql/logs:/var/log/mysql`              | 映射日志目录                     |
| `--restart unless-stopped`                              | 容器意外停止或系统重启时自动启动 |
| `mysql:8.0.16`                                          | 使用最新版的 MySQL 镜像          |

## 4.后续配置

### 4.1. 进入镜像并登录

密码：123456 运行镜像时设置root密码为123456

```bash
sudo docker exec -it mysql mysql -uroot -p
```

### 4.2. 新密码从任何主机登录。

```SQL
ALTER USER 'root'@'%' IDENTIFIED BY '123456';
```

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

