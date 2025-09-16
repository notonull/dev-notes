#!/bin/bash

# MongoDB服务部署脚本
# 作者: Generated Script
# 服务: MongoDB

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

# MongoDB服务安装
install() {
    log_step "开始部署MongoDB服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "mongo:latest"
    
    # 创建目录
    log_info "创建MongoDB目录结构..."
    mkdir -p /opt/server/mongodb/data
    
    # 创建docker-compose.yml
    log_info "创建MongoDB docker-compose.yml..."
    cat > /opt/server/mongodb/docker-compose.yml << 'EOF'
version: "3.9"

services:
  mongodb:
    image: mongo:latest
    container_name: mongodb
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: 123456
      MONGO_INITDB_DATABASE: yapi
    volumes:
      - /opt/server/mongodb/data:/data/db
    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动MongoDB服务..."
    cd /opt/server/mongodb
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

# 获取镜像名
get_image() {
    echo "mongo:latest"
}