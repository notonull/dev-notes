---
title: 【Linux】【Docker】整合统一安装脚本
copyright: CC-BY-4.0
tags:
  - linux
  - docker
createTime: 2025/09/16 02:22:56
permalink: /blog/8k0cq39j/
---

```sh
#!/bin/bash

# Docker服务自动化部署脚本
# 作者: Generated Script
# 日期: $(date)
# 服务器IP: 192.168.1.12

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检查Docker和Docker Compose是否安装
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    log_info "Docker环境检查通过"
}

# 创建基础目录结构
create_base_structure() {
    log_step "创建基础目录结构..."
    mkdir -p /opt/server
    log_info "基础目录结构创建完成"
}


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

# Jenkins服务部署
deploy_jenkins() {
    log_step "开始部署Jenkins服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "jenkins/jenkins:lts"
    
    # 创建目录
    log_info "创建Jenkins目录结构..."
    mkdir -p /opt/server/jenkins/{data,logs}
    
    # 创建docker-compose.yml
    log_info "创建Jenkins docker-compose.yml..."
    cat > /opt/server/jenkins/docker-compose.yml << 'EOF'
version: "3.9"

services:
  jenkins:
    image: jenkins/jenkins:lts
    privileged: true
    container_name: jenkins
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      TZ: Asia/Shanghai
    volumes:
      - /opt/server/jenkins/data:/var/jenkins_home
      - /opt/server/jenkins/logs:/var/log/jenkins
    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动Jenkins服务..."
    cd /opt/server/jenkins
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "Jenkins服务部署成功！访问地址: http://192.168.1.12:8080/"
        log_info "等待Jenkins服务完全启动..."
        sleep 30
        
        # 获取Jenkins初始管理员密码
        if [ -f "/opt/server/jenkins/data/secrets/initialAdminPassword" ]; then
            initial_password=$(cat /opt/server/jenkins/data/secrets/initialAdminPassword)
            log_info "=========================================="
            log_info "Jenkins初始管理员密码: $initial_password"
            log_info "=========================================="
            log_info "请复制上面的密码用于Jenkins初始化配置"
        else
            log_warn "Jenkins初始密码文件未找到，请稍后查看或等待服务完全启动"
            log_info "您也可以手动查看: cat /opt/server/jenkins/data/secrets/initialAdminPassword"
        fi
        
        log_info "首次访问需要使用上面的初始密码进行配置"
    else
        log_error "Jenkins服务部署失败"
        return 1
    fi
}

# MinIO服务部署
deploy_minio() {
    log_step "开始部署MinIO服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "minio/minio:latest"
    
    # 创建目录
    log_info "创建MinIO目录结构..."
    mkdir -p /opt/server/minio/{data,config}
    
    # 创建docker-compose.yml
    log_info "创建MinIO docker-compose.yml..."
    cat > /opt/server/minio/docker-compose.yml << 'EOF'
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
      MINIO_ROOT_PASSWORD: admin,123
    volumes:
      - /opt/server/minio/data:/data
      - /opt/server/minio/config:/root/.minio
    command: server /data --console-address ":9090"
EOF
    
    # 启动服务
    log_info "启动MinIO服务..."
    cd /opt/server/minio
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "MinIO服务部署成功！访问地址: http://192.168.1.12:9000/"
        log_info "控制台地址: http://192.168.1.12:9090/"
        log_info "认证信息: admin/123456"
    else
        log_error "MinIO服务部署失败"
        return 1
    fi
}

# MongoDB服务部署
deploy_mongodb() {
    log_step "开始部署MongoDB服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "mongo:latest"
    
    # 创建目录
    log_info "创建MongoDB目录结构..."
    mkdir -p /opt/server/mongo/data
    
    # 创建docker-compose.yml
    log_info "创建MongoDB docker-compose.yml..."
    cat > /opt/server/mongo/docker-compose.yml << 'EOF'
version: "3.9"

services:
  mongo:
    image: mongo:latest
    container_name: mongo
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: 123456
      MONGO_INITDB_DATABASE: yapi
    volumes:
      - /opt/server/mongo/data:/data/db
    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动MongoDB服务..."
    cd /opt/server/mongo
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "MongoDB服务部署成功！访问地址: 192.168.1.12:27017"
        log_info "认证信息: root/123456"
        log_info "初始化数据库: yapi"
    else
        log_error "MongoDB服务部署失败"
        return 1
    fi
}

# MySQL服务部署
deploy_mysql() {
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

# Nacos服务部署
deploy_nacos() {
    log_step "开始部署Nacos服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "nacos/nacos-server:latest"
    
    # 创建目录
    log_info "创建Nacos目录结构..."
    mkdir -p /opt/server/nacos/{data,logs}
    
    # 创建docker-compose.yml
    log_info "创建Nacos docker-compose.yml..."
    cat > /opt/server/nacos/docker-compose.yml << 'EOF'
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
EOF
    
    # 启动服务
    log_info "启动Nacos服务..."
    cd /opt/server/nacos
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "Nacos服务部署成功！访问地址: http://192.168.1.12:9080/"
        log_info "认证信息: nacos/nacos"
    else
        log_error "Nacos服务部署失败"
        return 1
    fi
}

# Nexus服务部署
deploy_nexus() {
    log_step "开始部署Nexus服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "sonatype/nexus3:latest"
    
    # 创建目录
    log_info "创建Nexus目录结构..."
    mkdir -p /opt/server/nexus/data
    
    # 创建docker-compose.yml
    log_info "创建Nexus docker-compose.yml..."
    cat > /opt/server/nexus/docker-compose.yml << 'EOF'
version: "3.9"
services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    ports:
      - "8081:8081"
    volumes:
      - /opt/server/nexus/data:/nexus-data
    environment:
      TZ: Asia/Shanghai
    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动Nexus服务..."
    cd /opt/server/nexus
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "Nexus服务部署成功！访问地址: http://192.168.1.12:8081/"
        log_info "认证信息: admin/123456"
        log_warn "首次启动可能需要几分钟时间，请耐心等待"
    else
        log_error "Nexus服务部署失败"
        return 1
    fi
}

# Redis服务部署
deploy_redis() {
    log_step "开始部署Redis服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "redis:latest"
    
    # 创建目录
    log_info "创建Redis目录结构..."
    mkdir -p /opt/server/redis/data
    
    # 创建docker-compose.yml
    log_info "创建Redis docker-compose.yml..."
    cat > /opt/server/redis/docker-compose.yml << 'EOF'
version: "3.9"

services:
  redis:
    image: redis:latest
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - /opt/server/redis/data:/data
    command: >
      redis-server
      --bind 0.0.0.0
      --requirepass "123456"

    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动Redis服务..."
    cd /opt/server/redis
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "Redis服务部署成功！访问地址: 192.168.1.12:6379"
        log_info "认证密码: 123456"
    else
        log_error "Redis服务部署失败"
        return 1
    fi
}

# YApi服务部署
deploy_yapi() {
    log_step "开始部署YApi服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "jayfong/yapi:latest"
    
    # 创建目录
    log_info "创建YApi目录结构..."
    mkdir -p /opt/server/yapi
    
    # 创建docker-compose.yml
    log_info "创建YApi docker-compose.yml..."
    cat > /opt/server/yapi/docker-compose.yml << 'EOF'
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
EOF
    
    # 启动服务
    log_info "启动YApi服务..."
    cd /opt/server/yapi
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "YApi服务部署成功！访问地址: http://192.168.1.12:3000/"
        log_info "认证信息: admin@yapi.com/123456"
    else
        log_error "YApi服务部署失败"
        return 1
    fi
}

# 安装所有服务
install_all() {
    log_step "开始安装所有Docker服务..."
    
    # 检查环境
    check_root
    check_docker
    create_base_structure
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 安装顺序很重要：先安装基础服务，再安装依赖服务
    log_info "=== 开始安装基础服务 ==="
    
    # 1. 安装数据库服务
    deploy_mysql
    sleep 10
    
    deploy_mongodb
    sleep 5
    
    deploy_redis
    sleep 5
    
    # 2. 安装应用服务
    log_info "=== 开始安装应用服务 ==="
    
    deploy_jenkins
    sleep 5
    
    deploy_minio
    sleep 5
    
    deploy_nexus
    sleep 10
    
    deploy_nacos
    sleep 10
    
    deploy_yapi
    sleep 5
    
    # 计算总用时
    end_time=$(date +%s)
    total_time=$((end_time - start_time))
    
    log_info "=== 安装完成 ==="
    log_info "总用时: ${total_time}秒"
    
    # 显示服务状态
    show_services_status
}

# 显示所有服务状态
show_services_status() {
    log_step "显示所有服务状态..."
    
    echo ""
    echo "=================================================="
    echo "              服务部署状态总览"
    echo "=================================================="
    
    services=("jenkins" "minio" "mongo" "mysql" "nacos" "nexus" "redis" "yapi")
    ports=("8080" "9000" "27017" "3306" "9080" "8081" "6379" "3000")
    
    for i in "${!services[@]}"; do
        service=${services[$i]}
        port=${ports[$i]}
        
        if docker ps | grep -q "$service"; then
            echo -e "${GREEN}✓${NC} $service - 运行中 - http://192.168.1.12:$port/"
        else
            echo -e "${RED}✗${NC} $service - 未运行"
        fi
    done
    
    echo "=================================================="
    echo ""
    
    log_info "可以使用以下命令检查各服务日志:"
    echo "docker logs jenkins"
    echo "docker logs minio"
    echo "docker logs mongo"
    echo "docker logs mysql"
    echo "docker logs nacos"
    echo "docker logs nexus"
    echo "docker logs redis"
    echo "docker logs yapi"
}

# 启动所有服务
up_all() {
    log_step "启动所有Docker服务..."
    
    services_dirs=("/opt/server/mysql" "/opt/server/mongo" "/opt/server/redis" "/opt/server/jenkins" "/opt/server/minio" "/opt/server/nexus" "/opt/server/nacos" "/opt/server/yapi")
    
    for dir in "${services_dirs[@]}"; do
        if [ -d "$dir" ] && [ -f "$dir/docker-compose.yml" ]; then
            log_info "启动服务: $(basename $dir)"
            cd "$dir"
            docker compose up -d
            sleep 3
        fi
    done
    
    log_info "所有服务已启动"
    show_services_status
}

# 停止所有服务
down_all() {
    log_step "停止所有Docker服务..."
    
    services_dirs=("/opt/server/jenkins" "/opt/server/minio" "/opt/server/mongo" "/opt/server/mysql" "/opt/server/nacos" "/opt/server/nexus" "/opt/server/redis" "/opt/server/yapi")
    
    for dir in "${services_dirs[@]}"; do
        if [ -d "$dir" ] && [ -f "$dir/docker-compose.yml" ]; then
            log_info "停止服务: $(basename $dir)"
            cd "$dir"
            docker compose down
        fi
    done
    
    log_info "所有服务已停止"
}

# 启动单个服务
up_service() {
    local service_name=$1
    log_step "启动${service_name}服务..."
    
    if [ -d "/opt/server/$service_name" ] && [ -f "/opt/server/$service_name/docker-compose.yml" ]; then
        cd "/opt/server/$service_name"
        docker compose up -d
        log_info "${service_name}服务启动完成"
    else
        log_error "${service_name}服务未安装或配置文件缺失"
        return 1
    fi
}

# 停止单个服务
down_service() {
    local service_name=$1
    log_step "停止${service_name}服务..."
    
    if [ -d "/opt/server/$service_name" ] && [ -f "/opt/server/$service_name/docker-compose.yml" ]; then
        cd "/opt/server/$service_name"
        docker compose down
        log_info "${service_name}服务停止完成"
    else
        log_error "${service_name}服务未安装或配置文件缺失"
        return 1
    fi
}

# 查看单个服务日志
logs_service() {
    local service_name=$1
    log_step "查看${service_name}服务日志..."
    
    if [ -d "/opt/server/$service_name" ] && [ -f "/opt/server/$service_name/docker-compose.yml" ]; then
        cd "/opt/server/$service_name"
        docker compose logs -f
    else
        log_error "${service_name}服务未安装或配置文件缺失"
        return 1
    fi
}

# 卸载所有服务（危险操作）
uninstall_all() {
    log_warn "这将删除所有服务及其数据，此操作不可逆！"
    read -p "确认删除所有服务和数据？(yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        log_step "卸载所有Docker服务和数据..."
        
        # 停止所有服务
        down_all
        
        # 删除所有容器
        docker rm -f jenkins minio mongo mysql nacos nexus redis yapi 2>/dev/null || true
        
        # 删除数据目录
        rm -rf /opt/server
        
        log_info "所有服务和数据已卸载完成"
    else
        log_info "操作已取消"
    fi
}

# 卸载单个服务
uninstall_service() {
    local service_name=$1
    log_warn "这将删除${service_name}服务及其数据，此操作不可逆！"
    read -p "确认删除${service_name}服务和数据？(yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        log_step "卸载${service_name}服务..."
        
        # 停止服务
        down_service "$service_name"
        
        # 删除容器
        docker rm -f "$service_name" 2>/dev/null || true
        
        # 删除数据目录
        if [ -d "/opt/server/$service_name" ]; then
            rm -rf "/opt/server/$service_name"
            log_info "${service_name}服务和数据已卸载完成"
        else
            log_warn "${service_name}服务目录不存在"
        fi
    else
        log_info "操作已取消"
    fi
}

# 获取服务对应的镜像名
get_service_image() {
    local service_name=$1
    case "$service_name" in
        "jenkins")
            echo "jenkins/jenkins:lts"
            ;;
        "minio")
            echo "minio/minio:latest"
            ;;
        "mongo"|"mongodb")
            echo "mongo:latest"
            ;;
        "mysql")
            echo "mysql:8.0.16"
            ;;
        "nacos")
            echo "nacos/nacos-server:latest"
            ;;
        "nexus")
            echo "sonatype/nexus3:latest"
            ;;
        "redis")
            echo "redis:latest"
            ;;
        "yapi")
            echo "jayfong/yapi:latest"
            ;;
        *)
            echo ""
            ;;
    esac
}

# 删除所有服务镜像
rmi_all() {
    log_warn "这将删除所有服务的Docker镜像！"
    read -p "确认删除所有服务镜像？(yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        log_step "删除所有服务镜像..."
        
        images=(
            "jenkins/jenkins:lts"
            "minio/minio:latest"
            "mongo:latest"
            "mysql:8.0.16"
            "nacos/nacos-server:latest"
            "sonatype/nexus3:latest"
            "redis:latest"
            "jayfong/yapi:latest"
        )
        
        for image in "${images[@]}"; do
            local image_exists=$(docker images -q "$image" 2>/dev/null)
            if [ -n "$image_exists" ]; then
                log_info "删除镜像: $image"
                docker rmi "$image" 2>/dev/null || log_warn "镜像 $image 删除失败（可能正在被使用）"
            else
                log_info "镜像 $image 不存在，跳过删除"
            fi
        done
        
        log_info "镜像删除操作完成"
    else
        log_info "操作已取消"
    fi
}

# 删除指定服务镜像
rmi_service() {
    local service_name=$1
    local image_name=$(get_service_image "$service_name")
    
    if [ -z "$image_name" ]; then
        log_error "不支持的服务: $service_name"
        return 1
    fi
    
    log_warn "这将删除${service_name}服务的Docker镜像: $image_name"
    read -p "确认删除镜像？(yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        log_step "删除${service_name}服务镜像..."
        
        local image_exists=$(docker images -q "$image_name" 2>/dev/null)
        if [ -n "$image_exists" ]; then
            docker rmi "$image_name" 2>/dev/null
            if [ $? -eq 0 ]; then
                log_info "镜像 $image_name 删除成功"
            else
                log_error "镜像 $image_name 删除失败（可能正在被使用）"
                log_info "请先停止相关容器: sudo ./docker_services_deploy.sh down $service_name"
                return 1
            fi
        else
            log_info "镜像 $image_name 不存在"
        fi
    else
        log_info "操作已取消"
    fi
}

# 帮助信息
show_help() {
    echo ""
    echo "Docker服务自动化管理脚本"
    echo ""
    echo "用法: $0 [命令] [服务名]"
    echo ""
    echo "服务管理命令:"
    echo "  install              安装所有服务"
    echo "  install [服务名]      安装指定服务"
    echo "  up                   启动所有服务"
    echo "  up [服务名]          启动指定服务"
    echo "  down                 停止所有服务"
    echo "  down [服务名]        停止指定服务"
    echo "  logs [服务名]        查看指定服务日志"
    echo "  rmi                  删除所有服务镜像（危险操作）"
    echo "  rmi [服务名]         删除指定服务镜像（危险操作）"
    echo "  uninstall            卸载所有服务（危险操作）"
    echo "  uninstall [服务名]   卸载指定服务（危险操作）"
    echo "  status               显示所有服务状态"
    echo "  help                 显示此帮助信息"
    echo ""
    echo "支持的服务名:"
    echo "  jenkins, minio, mongo, mysql, nacos, nexus, redis, yapi"
    echo ""
    echo "示例:"
    echo "  $0 install           # 安装所有服务"
    echo "  $0 install jenkins   # 仅安装Jenkins"
    echo "  $0 up                # 启动所有服务"
    echo "  $0 up jenkins        # 启动Jenkins服务"
    echo "  $0 down jenkins      # 停止Jenkins服务"
    echo "  $0 logs jenkins      # 查看Jenkins服务日志"
    echo "  $0 rmi               # 删除所有服务镜像"
    echo "  $0 rmi jenkins       # 删除Jenkins服务镜像"
    echo "  $0 uninstall jenkins # 卸载Jenkins服务"
    echo "  $0 status            # 查看服务状态"
    echo ""
    echo "注意: 安装服务时会自动拉取对应的Docker镜像"
    echo ""
}

# 主函数
main() {
    local command=$1
    local service=$2
    
    case "$command" in
        "install")
            if [ -z "$service" ]; then
                install_all
            else
                case "$service" in
                    "jenkins")
                        check_root && check_docker && create_base_structure && deploy_jenkins
                        ;;
                    "minio")
                        check_root && check_docker && create_base_structure && deploy_minio
                        ;;
                    "mongo"|"mongodb")
                        check_root && check_docker && create_base_structure && deploy_mongodb
                        ;;
                    "mysql")
                        check_root && check_docker && create_base_structure && deploy_mysql
                        ;;
                    "nacos")
                        check_root && check_docker && create_base_structure && deploy_nacos
                        ;;
                    "nexus")
                        check_root && check_docker && create_base_structure && deploy_nexus
                        ;;
                    "redis")
                        check_root && check_docker && create_base_structure && deploy_redis
                        ;;
                    "yapi")
                        check_root && check_docker && create_base_structure && deploy_yapi
                        ;;
                    *)
                        log_error "不支持的服务: $service"
                        show_help
                        exit 1
                        ;;
                esac
            fi
            ;;
        "up")
            if [ -z "$service" ]; then
                up_all
            else
                up_service "$service"
            fi
            ;;
        "down")
            if [ -z "$service" ]; then
                down_all
            else
                down_service "$service"
            fi
            ;;
        "logs")
            if [ -z "$service" ]; then
                log_error "请指定要查看日志的服务名"
                show_help
                exit 1
            else
                logs_service "$service"
            fi
            ;;
        "rmi")
            if [ -z "$service" ]; then
                rmi_all
            else
                rmi_service "$service"
            fi
            ;;
        "uninstall")
            if [ -z "$service" ]; then
                uninstall_all
            else
                uninstall_service "$service"
            fi
            ;;
        "status")
            show_services_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "无效的命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 如果没有参数，显示帮助
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# 执行主函数
main "$@"
```



