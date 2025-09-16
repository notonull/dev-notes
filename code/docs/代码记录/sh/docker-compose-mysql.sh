#!/bin/bash

# MySQL服务部署脚本
# 作者: Generated Script
# 服务: MySQL

# 检查镜像是否存在，不存在则拉取
check_and_pull_image() {
    local image_name=$1
    local image_exists=$(docker images -q "$image_name" 2>/dev/null)
    
    if [ -z "$image_exists" ]; then
        log_info "镜像 $image_name 不存在，开始拉取..."
        docker pull "$image_name"
        if [ $? -eq 0 ]; then
            log_info "镜像 $image_name 拉取成功"
        else
            log_error "镜像 $image_name 拉取失败"
            return 1
        fi
    else
        log_info "镜像 $image_name 已存在，跳过拉取"
    fi
}

# MySQL服务安装
install() {
    log_step "开始部署MySQL服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "mysql:8.0.16"
    
    # 创建目录
    log_info "创建MySQL目录结构..."
    mkdir -p /opt/server/mysql/{conf,data,logs,mysql-files}
    
    # 创建配置文件
    log_info "创建MySQL配置文件..."
    cat > /opt/server/mysql/conf/my.cnf << 'EOF'
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
EOF
    
    # 创建docker-compose.yml
    log_info "创建MySQL docker-compose.yml..."
    cat > /opt/server/mysql/docker-compose.yml << 'EOF'
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
EOF
    
    # 启动服务
    log_info "启动MySQL服务..."
    cd /opt/server/mysql
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "MySQL服务部署成功！访问地址: 192.168.1.12:3306"
        log_info "认证信息: root/123456"
        log_info "等待MySQL服务完全启动..."
        sleep 30
        log_info "配置MySQL远程访问权限..."
        docker exec mysql mysql -uroot -p123456 -e "ALTER USER 'root'@'%' IDENTIFIED BY '123456'; FLUSH PRIVILEGES;"
        log_info "创建Nacos数据库..."
        docker exec mysql mysql -uroot -p123456 -e "CREATE DATABASE IF NOT EXISTS nacos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    else
        log_error "MySQL服务部署失败"
        return 1
    fi
}

# 获取镜像名
get_image() {
    echo "mysql:8.0.16"
}