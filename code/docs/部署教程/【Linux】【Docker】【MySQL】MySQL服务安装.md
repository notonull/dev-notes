---
title: 【Linux】【Docker】【MySQL】MySQL服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - mysql
createTime: 2025/03/18 09:00:00
permalink: /blog/zpxci6jd/
---
[[toc]]

#### 【Linux】【Docker】【MySQL】MySQL服务安装

##### 1.新建宿主机挂载目录

```bash
mkdir -p /opt/app/mysql8.0/{conf}{data}{logs}
```
##### 2.查询docker hub镜像
```bash
sudo docker search mysql
```
##### 4.拉取镜像
```bash
sudo docker pull mysql
```
##### 5.查看本地镜像
```bash
sudo docker images
```
##### 6.配置my.cnf

###### 6.1. 新建 my.cnf

```bash
cd /opt/app/mysql8.0/conf
vim my.cnf
```

###### 6.2.my.cnf

```
[client]
#设置客户端默认字符集utf8mb4
default-character-set=utf8mb4
[mysql]
#设置服务器默认字符集为utf8mb4
default-character-set=utf8mb4
[mysqld]
#配置服务器的服务号，具备日后需要集群做准备
server-id = 1
#开启MySQL数据库的二进制日志，用于记录用户对数据库的操作SQL语句，具备日后需要集群做准备
log-bin=mysql-bin
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

##### 7.运行镜像

```bash
sudo docker run -d \
  --name mysql8.0 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -p 3306:3306 \
  -v /opt/app/mysql8.0/data:/var/lib/mysql \
  -v /opt/app/mysql8.0/conf/my.cnf:/etc/mysql/my.cnf \
  -v /opt/app/mysql8.0/logs:/var/log/mysql \
  --restart always \
  mysql:latest
```

| 指令      | 描述     |
| --------- | -------- |
| -d        | 后台运行 |
| --name    | 容器名称 |
| -e        | 容器环境 |
| -p        | 映射端口 |
| -v        | 卷挂载   |
| --restart | 重启策略 |

##### 8.服务设置

###### 8.1. 进入镜像并登录

```bash
sudo docker exec -it mysql8.0 mysql -uroot -p
```

###### 8.2. 新密码从任何主机登录。

```SQL
ALTER USER 'root'@'%' IDENTIFIED BY '123456';
```

##### 常用命令

```bash
docker ps
docker images
docker logs #id
docker rm #id
docker stop #name
docker start #name
```