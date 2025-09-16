#!/bin/bash

# Redis服务部署脚本
# 作者: Generated Script
# 服务: Redis

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

# Redis服务安装
install() {
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

# 获取镜像名
get_image() {
    echo "redis:latest"
}