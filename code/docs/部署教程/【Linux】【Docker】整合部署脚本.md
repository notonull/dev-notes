---
title: 【Linux】【Docker】整合部署脚本
copyright: CC-BY-4.0
tags:
  - linux
  - docker
createTime: 2025/09/15 05:42:39
permalink: /blog/6n6uim8h/
---

```sh
#!/bin/bash
# 自动化部署所有 Docker 服务
# 作者: aGeng
# 日期: 2025-09-15

set -e

BASE_DIR=/opt/server

declare -A SERVICES

# 定义服务目录和 docker-compose.yml 内容
SERVICES["jenkins"]="version: '3.9'
services:
  jenkins:
    image: jenkins/jenkins:lts
    privileged: true
    container_name: jenkins
    user: root
    ports:
      - '8080:8080'
      - '50000:50000'
    environment:
      TZ: Asia/Shanghai
    volumes:
      - ./data:/var/jenkins_home
      - ./logs:/var/log/jenkins
    restart: unless-stopped
"

SERVICES["minio"]="version: '3.9'
services:
  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    ports:
      - '9000:9000'
      - '9090:9090'
    environment:
      MINIO_ROOT_USER: ewecan
      MINIO_ROOT_PASSWORD: Ewecan,123
    volumes:
      - ./data:/data
      - ./config:/root/.minio
    command: server /data --console-address ':9090'
"

SERVICES["mongo"]="version: '3.9'
services:
  mongo:
    image: mongo:latest
    container_name: mongo
    ports:
      - '27017:27017'
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: Ewecan,123
      MONGO_INITDB_DATABASE: yapi
    volumes:
      - ./data:/data/db
    restart: unless-stopped
"

SERVICES["mysql"]="version: '3.9'
services:
  mysql:
    image: mysql:8.0.16
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: Ewecan,123
    ports:
      - '3306:3306'
    volumes:
      - ./data:/var/lib/mysql
      - ./mysql-files:/var/lib/mysql-files
      - ./conf/my.cnf:/etc/mysql/my.cnf
      - ./logs:/var/log/mysql
    restart: unless-stopped
"

SERVICES["nacos"]="version: '3.9'
services:
  nacos:
    image: nacos/nacos-server:latest
    container_name: nacos
    environment:
      - MODE=standalone
      - SPRING_DATASOURCE_PLATFORM=mysql
      - MYSQL_SERVICE_HOST=192.168.0.209
      - MYSQL_SERVICE_DB_NAME=nacos
      - MYSQL_SERVICE_PORT=3306
      - MYSQL_SERVICE_USER=root
      - MYSQL_SERVICE_PASSWORD=Ewecan,123
      - MYSQL_SERVICE_DB_PARAM=characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
    ports:
      - '9080:8080'
      - '8848:8848'
      - '9848:9848'
    volumes:
      - ./data:/home/nacos/nacos-data
      - ./logs:/home/nacos/logs
    restart: unless-stopped
"

SERVICES["nexus"]="version: '3.9'
services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    ports:
      - '8081:8081'
    volumes:
      - ./data:/nexus-data
    environment:
      TZ: Asia/Shanghai
    restart: unless-stopped
"

SERVICES["redis"]="version: '3.9'
services:
  redis:
    image: redis:latest
    container_name: redis
    ports:
      - '6379:6379'
    volumes:
      - ./data:/data
    command: redis-server --bind 0.0.0.0 --requirepass 'Ewecan,123'
    restart: unless-stopped
"

SERVICES["yapi"]="version: '3.9'
services:
  yapi-web:
    image: jayfong/yapi:latest
    container_name: yapi
    ports:
      - '3000:3000'
    environment:
      - YAPI_ADMIN_ACCOUNT=admin@ewecan.com
      - YAPI_ADMIN_PASSWORD=ewecan,123
      - YAPI_CLOSE_REGISTER=true
      - YAPI_DB_SERVERNAME=192.168.0.209
      - YAPI_DB_PORT=27017
      - YAPI_DB_DATABASE=yapi
      - YAPI_DB_USER=root
      - YAPI_DB_PASS=Ewecan,123
      - YAPI_DB_AUTH_SOURCE=admin
    restart: unless-stopped
"

# MySQL my.cnf 内容
MYSQL_CONF="[client]
default-character-set=utf8mb4
[mysql]
default-character-set=utf8mb4
[mysqld]
server-id = 1
binlog_expire_logs_seconds = 2592000
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
max_connections=1000
symbolic-links=0
default-time_zone = '+8:00'
"

# 自动生成目录和 docker-compose.yml
for service in "${!SERVICES[@]}"; do
    echo "📂 创建目录 $BASE_DIR/$service"
    mkdir -p $BASE_DIR/$service

    # 针对 MySQL 还需要子目录
    if [ "$service" == "mysql" ]; then
        mkdir -p $BASE_DIR/mysql/data $BASE_DIR/mysql/mysql-files $BASE_DIR/mysql/logs $BASE_DIR/mysql/conf
        echo "$MYSQL_CONF" > $BASE_DIR/mysql/conf/my.cnf
    fi

    # 针对 MinIO 需要 config
    if [ "$service" == "minio" ]; then
        mkdir -p $BASE_DIR/minio/data $BASE_DIR/minio/config
    fi

    # Mongo、Jenkins、Redis、Nacos、Nexus、YApi 创建 data/logs 目录
    if [ "$service" == "jenkins" ]; then
        mkdir -p $BASE_DIR/jenkins/data $BASE_DIR/jenkins/logs
    fi
    if [ "$service" == "mongo" ]; then
        mkdir -p $BASE_DIR/mongo/data
    fi
    if [ "$service" == "nacos" ]; then
        mkdir -p $BASE_DIR/nacos/data $BASE_DIR/nacos/logs
    fi
    if [ "$service" == "nexus" ]; then
        mkdir -p $BASE_DIR/nexus/data
    fi
    if [ "$service" == "redis" ]; then
        mkdir -p $BASE_DIR/redis/data
    fi

    # 写入 docker-compose.yml
    echo "📄 写入 $BASE_DIR/$service/docker-compose.yml"
    echo "${SERVICES[$service]}" > $BASE_DIR/$service/docker-compose.yml
done

# 一键拉取镜像并启动服务
for service in "${!SERVICES[@]}"; do
    DIR="$BASE_DIR/$service"
    echo "-------------------------------"
    echo "🚀 服务: $service"
    docker-compose -f $DIR/docker-compose.yml pull
    docker-compose -f $DIR/docker-compose.yml up -d
done

echo "✅ 所有服务已完成部署和启动"

```

